# Copyright 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

"""Lustre helpers: ``lfs`` protocol parsing plus the LNet transport layer.

Holds the Lustre-side logic: the ``lfs df`` / ``lfs check servers`` protocol parsing, and the LNet
transport layer (parsing ``lnetctl net show`` / ``lnetctl peer show`` and the ``lnetctl ping``
reachability probe) -- LNet is Lustre's own networking layer, driven by ``lnetctl``.
"""

import logging
import re
from dataclasses import dataclass, field
from typing import List, Optional

import yaml

from pcluster_diag.core.constants import EFA_LNET_NET, FSX_EFA_PING_TIMEOUT_SECONDS, FSX_LNET_SHOW_TIMEOUT_SECONDS
from pcluster_diag.util import kernel_module
from pcluster_diag.util.shell import time_command

logger = logging.getLogger(__name__)

# The out-of-tree kernel modules the Lustre client needs to speak Lustre.
LUSTRE_KERNEL_MODULES = ("lustre", "lnet")

# The loopback LNet net; never a real transport, so it is ignored when reporting active LNDs.
LOOPBACK_LNET_NET = "lo"

# Matches the target role (MDT/OST) embedded in a `lfs df` UUID or the `[OST:0]`/`[MDT:0]` mount tag.
_ROLE_RE = re.compile(r"(MDT|OST)", re.IGNORECASE)

# Matches a `lfs df -h` size column (e.g. "10.0T", "512", "1.5G"); healthy target rows start with one.
_SIZE_RE = re.compile(r"^\d[\d.]*[KMGTPE]?$")


@dataclass
class LustreTarget:
    """A per-target row parsed from ``lfs df -h`` output.

    Attributes:
        uuid: The target UUID as reported by ``lfs df`` (e.g. ``fs-abc-OST0001_UUID``).
        role: The target role (``OST`` or ``MDT``), or None when it cannot be determined.
        available: Whether the target reported healthy capacity (False for an error/inactive row).
        detail: The raw status text for an unavailable target (empty for a healthy one).
    """

    uuid: str
    role: Optional[str]
    available: bool
    detail: str = ""


def parse_lfs_df(output: str) -> List[LustreTarget]:
    """Parse ``lfs df -h`` output into per-target rows, ignoring the header and summary lines."""
    targets: List[LustreTarget] = []
    for raw in output.splitlines():
        line = raw.strip()
        if not line or line.startswith("UUID") or line.startswith("filesystem_summary"):
            continue
        target = _parse_target_line(line)
        if target is not None:
            targets.append(target)
    return targets


def unavailable_targets(output: str) -> List[LustreTarget]:
    """Return the parsed ``lfs df -h`` targets that are not available (down/inactive/errored)."""
    return [target for target in parse_lfs_df(output) if not target.available]


def _parse_target_line(line: str) -> Optional[LustreTarget]:
    """Parse a single ``lfs df -h`` body line into a ``LustreTarget``, or None when it is not one.

    A healthy target row carries a numeric ``bytes`` column as its second field (e.g.
    ``fs-abc-OST0000_UUID 10.0T ... /fsx[OST:0]``). A row that instead carries a status message
    (e.g. ``fs-abc-OST0001_UUID : Resource temporarily unavailable``) marks the target unavailable.
    """
    tokens = line.split()
    if len(tokens) < 2:
        return None
    uuid = tokens[0]
    role_match = _ROLE_RE.search(uuid) or _ROLE_RE.search(line)
    role = role_match.group(1).upper() if role_match else None

    if _SIZE_RE.match(tokens[1]):
        return LustreTarget(uuid=uuid, role=role, available=True)

    # Not a capacity row: only treat it as an (unavailable) target when it names a target role.
    if role is None:
        return None
    detail = line.removeprefix(uuid).strip().lstrip(":").strip()
    return LustreTarget(uuid=uuid, role=role, available=False, detail=detail)


def lustre_client_version() -> Optional[str]:
    """Return the Lustre client version (from the ``lustre`` kernel module), or None when unavailable."""
    return kernel_module.module_version("lustre")


# --- LNet transport: lnetctl net show parsing -----------------------------------------


@dataclass
class LnetNi:
    """A single local network interface (NI) parsed from ``lnetctl net show``.

    Attributes:
        nid: The Lustre network id (e.g. ``10.0.0.1@efa``).
        status: The interface status string (e.g. ``up``), or None when absent.
        interfaces: The underlying device names bound to this NI (e.g. ``["efa0"]``).
        send_count: Packets sent, from ``lnetctl net show -v`` statistics (None when not verbose).
        recv_count: Packets received, from ``lnetctl net show -v`` statistics (None when not verbose).
        health_value: The NI health value, from ``-v`` health stats (None when not verbose/absent).
    """

    nid: str
    status: Optional[str] = None
    interfaces: List[str] = field(default_factory=list)
    send_count: Optional[int] = None
    recv_count: Optional[int] = None
    health_value: Optional[int] = None


@dataclass
class LnetNet:
    """A configured LNet network parsed from ``lnetctl net show``.

    Attributes:
        net_type: The LND net type (e.g. ``tcp``, ``efa``, ``o2ib``, or ``lo`` for loopback).
        local_nis: The local network interfaces configured on this net.
    """

    net_type: str
    local_nis: List[LnetNi] = field(default_factory=list)


def parse_lnet_net_show(output: str) -> List[LnetNet]:
    """Parse ``lnetctl net show`` (or ``-v``) YAML into ``LnetNet`` entries (empty when unparseable).

    ``lnetctl`` emits YAML with a top-level ``net`` list; each entry carries a ``net type`` and a
    ``local NI(s)`` list. Malformed output is treated as "no nets" rather than raising, so a broken
    ``lnetctl`` never wedges the check.
    """
    try:
        data = yaml.safe_load(output)
    except yaml.YAMLError as error:
        logger.warning("Could not parse lnetctl net show output as YAML: %s", error)
        return []
    if not isinstance(data, dict):
        return []
    nets: List[LnetNet] = []
    for entry in data.get("net") or []:
        if not isinstance(entry, dict):
            continue
        net_type = entry.get("net type")
        if not net_type:
            continue
        nis = [_parse_lnet_ni(ni) for ni in (entry.get("local NI(s)") or []) if isinstance(ni, dict)]
        nets.append(LnetNet(net_type=str(net_type), local_nis=nis))
    return nets


def _parse_lnet_ni(ni: dict) -> LnetNi:
    """Parse one ``local NI(s)`` mapping from ``lnetctl net show`` into an ``LnetNi``."""
    raw_interfaces = ni.get("interfaces")
    if isinstance(raw_interfaces, dict):
        interfaces = [str(value) for value in raw_interfaces.values()]
    elif isinstance(raw_interfaces, list):
        interfaces = [str(value) for value in raw_interfaces]
    else:
        interfaces = []
    statistics = ni.get("statistics") or {}
    health_stats = ni.get("health stats") or {}
    status = ni.get("status")
    return LnetNi(
        nid=str(ni.get("nid") or ""),
        status=str(status) if status is not None else None,
        interfaces=interfaces,
        send_count=_as_int(statistics.get("send_count")),
        recv_count=_as_int(statistics.get("recv_count")),
        health_value=_as_int(health_stats.get("health value")),
    )


def active_lnds(nets: List[LnetNet]) -> List[str]:
    """Return the active LND net types (in order), excluding the loopback net."""
    return [net.net_type for net in nets if net.net_type != LOOPBACK_LNET_NET]


def lnet_net(nets: List[LnetNet], net_type: str) -> Optional[LnetNet]:
    """Return the ``LnetNet`` with ``net_type``, or None when it is not configured."""
    return next((net for net in nets if net.net_type == net_type), None)


def lnet_bound_interfaces(nets: List[LnetNet], net_type: str) -> List[str]:
    """Return the underlying device names bound to ``net_type`` across all its NIs (empty when none)."""
    net = lnet_net(nets, net_type)
    if net is None:
        return []
    interfaces: List[str] = []
    for ni in net.local_nis:
        interfaces.extend(ni.interfaces)
    return interfaces


def local_nids(nets: List[LnetNet], net_type: str) -> List[str]:
    """Return the local nids configured on ``net_type`` (empty when the net is absent)."""
    net = lnet_net(nets, net_type)
    if net is None:
        return []
    return [ni.nid for ni in net.local_nis if ni.nid]


# --- LNet transport: lnetctl peer show parsing ----------------------------------------


def parse_lnet_peer_show(output: str) -> List[str]:
    """Return the peer nids parsed from ``lnetctl peer show`` YAML (empty when unparseable/none).

    ``lnetctl peer show`` emits a top-level ``peer`` list; each entry carries a ``primary nid`` and a
    ``peer ni`` list of ``nid`` mappings. Both are collected so callers can pick, e.g., the ``@efa`` nids.
    """
    try:
        data = yaml.safe_load(output)
    except yaml.YAMLError as error:
        logger.warning("Could not parse lnetctl peer show output as YAML: %s", error)
        return []
    if not isinstance(data, dict):
        return []
    nids: List[str] = []
    for entry in data.get("peer") or []:
        if not isinstance(entry, dict):
            continue
        primary = entry.get("primary nid")
        if primary:
            nids.append(str(primary))
        for peer_ni in entry.get("peer ni") or []:
            if isinstance(peer_ni, dict) and peer_ni.get("nid"):
                nids.append(str(peer_ni["nid"]))
    return nids


def nids_on_net(nids: List[str], net_type: str) -> List[str]:
    """Return the nids in ``nids`` whose LND suffix matches ``net_type`` (e.g. ``efa``), de-duplicated."""
    suffix = "@" + net_type
    seen = set()
    matched: List[str] = []
    for nid in nids:
        if nid.endswith(suffix) and nid not in seen:
            seen.add(nid)
            matched.append(nid)
    return matched


# --- LNet transport: the lnetctl ping reachability probe ------------------------------


def efa_peer_nids() -> List[str]:
    """Return every ``@efa`` peer nid from ``lnetctl peer show`` (empty when none/unavailable).

    The peer table can hold an ``@efa`` NID that answers nothing even when the fabric is healthy: a
    failed ``lnetctl ping`` to a NID nothing serves leaves a peer entry behind, carrying that NID as its
    own primary with no ``@tcp`` rail (a discovered peer instead has a ``@tcp`` primary and ``@efa`` as a
    secondary rail). Callers therefore probe the whole set rather than trusting any single peer.
    """
    result = time_command(["lnetctl", "peer", "show"], timeout=FSX_LNET_SHOW_TIMEOUT_SECONDS)
    if result.timed_out or result.returncode != 0:
        return []
    return nids_on_net(parse_lnet_peer_show(result.stdout), EFA_LNET_NET)


def efa_peer_nid() -> Optional[str]:
    """Return the first ``@efa`` peer nid from ``lnetctl peer show``, or None when none is available."""
    efa_peers = efa_peer_nids()
    return efa_peers[0] if efa_peers else None


def efa_ping_works(source_nid: str, peer_nid: str) -> bool:
    """Return whether ``lnetctl ping --source <source_nid> <peer_nid>`` succeeds within the timeout.

    A hang or a non-zero exit both mean the EFA data path is not working; only a clean success is True.
    """
    result = time_command(["lnetctl", "ping", "--source", source_nid, peer_nid], timeout=FSX_EFA_PING_TIMEOUT_SECONDS)
    return not (result.timed_out or result.returncode != 0)


def _as_int(value) -> Optional[int]:
    """Coerce ``value`` to an int, or None when it is missing or not an integer."""
    if value is None:
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


# --- lfs check servers parsing --------------------------------------------------------

# Matches an error line such as: check 'fs-OST0001-osc-ffff': Input/output error (5)
_CHECK_ERROR_RE = re.compile(r"check '(?P<target>[^']+)':\s*(?P<detail>.*)")


@dataclass
class ServerCheck:
    """A single per-target line parsed from ``lfs check servers``.

    Attributes:
        target: The target (obd) name (e.g. ``fs-OST0001-osc-ffff``).
        active: Whether the target reported ``active`` (reachable).
        detail: The raw error/status text for a non-active target (empty for an active one).
    """

    target: str
    active: bool
    detail: str = ""


def parse_lfs_check_servers(output: str) -> List[ServerCheck]:
    """Parse ``lfs check servers`` output into per-target ``ServerCheck`` rows.

    ``lfs check servers`` reports each target either as ``<target> active.`` or as an error line such as
    ``check '<target>': Input/output error (5)``. Both shapes are parsed; unrecognized lines are ignored.
    """
    results: List[ServerCheck] = []
    for raw in output.splitlines():
        line = raw.strip()
        if not line:
            continue
        error_match = _CHECK_ERROR_RE.search(line)
        if error_match:
            detail = error_match.group("detail").strip()
            results.append(ServerCheck(target=error_match.group("target"), active=False, detail=detail))
            continue
        tokens = line.split()
        if len(tokens) < 2:
            continue
        status = " ".join(tokens[1:])
        active = "active" in status.lower()
        results.append(ServerCheck(target=tokens[0], active=active, detail="" if active else status))
    return results


def unreachable_servers(output: str) -> List[ServerCheck]:
    """Return the ``lfs check servers`` targets that did not report active (reachable)."""
    return [server for server in parse_lfs_check_servers(output) if not server.active]
