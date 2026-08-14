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

"""Checks diagnosing FSx for Lustre client health, mount presence, and server reachability.

The failure class these checks target (EFA fabric down, an OSS/OST unreachable, a wedged ``ls -al``)
manifests as Lustre operations *blocking* rather than erroring quickly. Every command that can hang is
therefore run through :func:`pcluster_diag.util.shell.time_command` with a bounded timeout, and a
timeout is treated as a distinct, first-class failure mode rather than an exception. The fast, local
queries (kernel-module presence, reading ``/proc/mounts``) go through ``run_command``.

The always-on Lustre verifications are consolidated into one :class:`LustreFilesystem` check whose ``run``
executes each probe in isolation and aggregates their findings. The probes are:

- **client** -- the ``lustre``/``lnet`` kernel modules are available for the running kernel (so a broken
  client is reported as its own root cause) and loaded, plus the client version as info, and -- when the
  client version is known -- that it meets the per-``base_os`` minimum (rhel8/rocky8 ship the 2.12 client,
  every other supported OS ships 2.15); this is a general Lustre floor, applied to every FsxLustre mount;
- **mount presence** -- each configured Lustre ``MountDir`` is actually mounted (a cheap, non-hanging
  ``/proc/mounts`` check, so "not mounted" is not misreported downstream as "unreachable");
- **filesystem reachability** -- ``lfs df -h`` per mount (the recommended first-line reachability command),
  classifying a hang, an error, or a down target;
- **LNet transport** -- ``lnetctl net show`` reporting the active LNDs (tcp/efa/o2ib), surfacing the
  EFA-vs-TCP transport state;
- **EFA mount** -- skipped entirely on a ``base_os`` where EFA-for-Lustre is unsupported (rhel8/rocky8).
  Otherwise run whenever EFA-for-Lustre is *expected* (an ``@efa`` LNet net is configured, or the
  ``configure-efa-fsx-lustre-client`` systemd service is installed on this node). It first verifies the
  EFA prerequisites the way the official FSx EFA-Lustre client setup does -- the ``kefalnd`` module (that
  setup's own definition of "the Lustre client supports EFA"), the EFA driver version, and, on the p6+
  instance families, the kefalnd version -- then the state of the ``configure-efa-fsx-lustre-client.service``
  that (re)configures LNet on every boot, then detects common root causes: no EFA device bound to LNet at
  all (so Lustre falls back to TCP), fewer devices bound than the instance type is expected to bind (the
  expected count comes from a per-instance-family table, NOT the raw device count -- several families bind
  only a subset by design, and instance types with no known/static expectation are not flagged beyond the
  "none bound" case), and a non-working EFA data path (typically a missing self-referencing security-group
  rule).
  See https://docs.aws.amazon.com/fsx/latest/LustreGuide/configure-efa-clients.html

:class:`FsxTargetsAreReachable` is kept separate because it is a heavier, opt-in
(``approval_required``) deep probe (``lfs check servers`` + per-target import state); the framework's
approval gate is per-check, so folding it into the always-on check would either force the deep probe to
run every time or gate the whole check behind a prompt. It is currently not registered -- see its docstring.

:class:`LustreFilesystem` runs on every node type that has a FsxLustre mount configured, and skips
(SKIPPED_NOT_APPLICABLE) when the cluster configures no FsxLustre filesystem. Every probe is read-only.
"""

import logging
import shutil
from dataclasses import dataclass, field
from typing import List

from pcluster_diag.core.constants import (
    EFA_INFINIBAND_SYSFS,
    EFA_KEFALND_KERNEL_MODULE,
    EFA_LNET_NET,
    EFA_LUSTRE_SYSTEMD_SERVICE,
    EFA_LUSTRE_UNSUPPORTED_OSES,
    FSX_LFS_CHECK_TIMEOUT_SECONDS,
    FSX_LFS_DF_TIMEOUT_SECONDS,
    FSX_LNET_SHOW_TIMEOUT_SECONDS,
    FSX_OST_QUERY_TIMEOUT_SECONDS,
    HEALTHY_TARGET_STATE,
    LUSTRE_CLIENT_MIN_VERSION_BY_OS,
    LUSTRE_CLIENT_MIN_VERSION_DEFAULT,
    MIN_EFA_DRIVER_VERSION,
    MIN_KEFALND_VERSION_P6,
)
from pcluster_diag.core.probe import run_probe
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context
from pcluster_diag.models.finding import CheckError, CheckInfo, CheckWarning
from pcluster_diag.models.result import INTERNAL_ERROR_CODE, Result
from pcluster_diag.util import efa, kernel_module, lustre, services, shared_storage
from pcluster_diag.util.shell import time_command

logger = logging.getLogger(__name__)


def _has_lustre(context: Context) -> bool:
    """Return whether the cluster configuration declares at least one FsxLustre mount."""
    return bool(shared_storage.lustre_mounts(context))


def _base_os(context: Context):
    """Return the cluster ``base_os`` token from dna.json (e.g. ``alinux2023``, ``rhel8``), or None."""
    return ((context.dna_json or {}).get("cluster") or {}).get("base_os")


@dataclass
class _LnetSnapshot:
    """One shared ``lnetctl net show -v`` result, consumed by both the LNet and EFA probes.

    ``lnetctl net show -v`` is run once per check invocation (it is the input for both the transport
    probe and the EFA probe), so the two probes share this snapshot instead of each shelling out.

    Attributes:
        timed_out: Whether the ``lnetctl`` call exceeded its bounded timeout (LNet may be wedged).
        unavailable: Whether ``lnetctl`` could not be run at all (e.g. the binary is not installed).
        nets: The parsed LNet nets (empty when the command timed out, was unavailable, or returned non-zero).
    """

    timed_out: bool
    unavailable: bool = False
    nets: list = field(default_factory=list)


class LustreFilesystem(Check):
    """Diagnose FSx for Lustre client health, mount presence, server reachability, and the EFA transport.

    Runs a sequence of read-only probes (client, mount presence, ``lfs df`` reachability, LNet transport,
    EFA mount) and aggregates their findings into a single Result. Each probe runs in isolation so one
    probe's crash does not sink its siblings. See the module docstring for the failure class and the
    per-probe rationale.
    """

    # --- Errors: client -----------------------------------------------------------------------
    NOT_INSTALLED = CheckError(
        1,
        "Lustre client is not installed though a FsxLustre filesystem is configured: the lustre/lnet "
        "kernel modules are not available for kernel {} (the client may not be installed, or may not "
        "have rebuilt after a kernel update).",
    )
    MODULES_NOT_LOADED = CheckError(2, "Lustre kernel modules are available but not loaded: {}.")

    # --- Errors: undeterminable checks (reserved E0 -> CHECK_ERROR, not FAILURE) ---------------
    # A version/family the check could not evaluate is reported as a CHECK_ERROR (the check could not
    # complete its assertion), distinct from a FAILURE (the assertion definitively failed). All carry the
    # reserved E0 code, which Result.from_findings maps to CHECK_ERROR when no real failure is also present.
    CLIENT_VERSION_UNDETERMINABLE = CheckError(
        INTERNAL_ERROR_CODE,
        "Could not determine the Lustre client version (version string {!r} is unparseable): the "
        "minimum-version check (>= {}) was not evaluated.",
    )
    EFA_DRIVER_VERSION_UNDETERMINABLE = CheckError(
        INTERNAL_ERROR_CODE,
        "Could not determine the EFA driver version: the minimum-version check (>= {}) was not evaluated.",
    )
    KEFALND_VERSION_UNDETERMINABLE = CheckError(
        INTERNAL_ERROR_CODE,
        "Could not determine the kefalnd version: the p6+ minimum-version check (>= {}) was not evaluated.",
    )
    INSTANCE_TYPE_UNDETERMINABLE = CheckError(
        INTERNAL_ERROR_CODE,
        "Could not determine the instance type (an IMDS error at startup): the p6+ kefalnd "
        "minimum-version check ({} >= {}) was not evaluated.",
    )

    # --- Errors: mount presence ---------------------------------------------------------------
    NOT_MOUNTED = CheckError(3, "'{}' ({}) is configured but not mounted.")

    # --- Errors: filesystem reachability ------------------------------------------------------
    LFS_DF_TIMED_OUT = CheckError(
        4,
        "lfs df -h on '{}' did not return within {}s -- the filesystem is hanging (server/OST unreachable).",
    )
    LFS_DF_FAILED = CheckError(5, "lfs df -h on '{}' failed: {}")
    TARGET_UNAVAILABLE = CheckError(6, "target {} on '{}' is not available (possible OST/MDT down).")

    # --- Errors: LNet transport ---------------------------------------------------------------
    LNETCTL_TIMED_OUT = CheckError(
        7, "lnetctl net show did not return within {}s -- LNet is not responding (transport may be wedged)."
    )
    LNET_NOT_CONFIGURED = CheckError(
        8, "LNet is not configured though a FsxLustre filesystem is configured (no LNet networks are present)."
    )

    # --- Errors: EFA mount --------------------------------------------------------------------
    NO_EFA_DEVICES = CheckError(
        9, "An EFA LNet net is configured but no EFA devices are exposed under {} -- EFA is not available."
    )
    NO_DEVICES_BOUND = CheckError(
        10,
        "{} EFA devices are exposed but none are bound to LNet -- Lustre will fall back to TCP. "
        "Re-run the EFA-Lustre client configuration.",
    )
    UNDERBOUND_DEVICES = CheckError(
        17,
        "Only {} of {} expected EFA devices are bound to LNet on {} -- Lustre will not use the full EFA "
        "fabric. Re-run the EFA-Lustre client configuration.",
    )
    EFA_PING_FAILED = CheckError(
        11,
        "EFA ping from {} to {} failed -- the EFA data path is not working. Check the security group "
        "has a self-referencing rule by SG-ID (EFA's SRD-over-MAC is not authorized by a 0.0.0.0/0 rule).",
    )

    # --- Errors: EFA prerequisites (checked before the EFA data-path probes) ------------------
    KEFALND_MISSING = CheckError(
        12,
        "EFA-for-Lustre is expected on this node but the kefalnd module is not available: the Lustre "
        "client does not support EFA (install a Lustre client with EFA support). See "
        "https://docs.aws.amazon.com/fsx/latest/LustreGuide/configure-efa-clients.html.",
    )
    EFA_DRIVER_TOO_OLD = CheckError(13, "EFA driver version {} is below the minimum {} required for EFA-for-Lustre.")
    KEFALND_TOO_OLD = CheckError(14, "kefalnd version {} is below the minimum {} required on p6+ instances ({}).")
    EFA_SERVICE_FAILED = CheckError(
        15,
        "The EFA-Lustre configuration service {} is in the failed state -- LNet was not configured for "
        "EFA (check `journalctl -u {}`); Lustre will fall back to TCP.",
    )
    CLIENT_TOO_OLD = CheckError(
        16, "Lustre client version {} is below the minimum {} the FSx EFA-Lustre setup requires."
    )

    # --- Warnings -----------------------------------------------------------------------------
    HEALTH_DEGRADED = CheckWarning(
        1, "LNet interface {} (net {}) shows connection-health degradation (health value {})."
    )
    NO_TRAFFIC = CheckWarning(
        2,
        "EFA LNet interface {} shows no traffic yet (send_count=0, recv_count=0). This is expected on an "
        "idle or freshly-booted node; if the node has been driving filesystem I/O it may indicate a silent "
        "TCP fallback.",
    )
    TCP_FALLBACK = CheckWarning(3, "target {} is connected over @tcp despite EFA being configured (TCP fallback).")

    # --- Infos --------------------------------------------------------------------------------
    CLIENT_VERSION = CheckInfo(1, "Lustre client version: {}.")
    ACTIVE_LNDS = CheckInfo(2, "Active LNet transports: {}.")
    EFA_SERVICE_ABSENT = CheckInfo(
        3,
        "The EFA-Lustre configuration service {} is not installed -- LNet is configured at runtime by the "
        "bootstrap script (expected when the EFA-Lustre client package is not used).",
    )
    EFA_SERVICE_ACTIVE = CheckInfo(4, "The EFA-Lustre configuration service {} is installed and not failed.")
    BOUND_DEVICES = CheckInfo(
        5,
        "{} of {} EFA devices are bound to LNet (some instance families bind a subset by design).",
    )
    EFA_DRIVER_VERSION = CheckInfo(6, "EFA driver version: {}.")
    KEFALND_VERSION = CheckInfo(7, "kefalnd (EFA LND) version: {}.")
    EFA_BINDING_REFERENCE = CheckInfo(
        8,
        "EFA-for-Lustre binding follows the FSx guide -- the expected number of EFA devices bound to LNet "
        "is instance-type-specific (some families bind a subset by design). See "
        "https://docs.aws.amazon.com/fsx/latest/LustreGuide/configure-efa-clients.html",
    )
    LNETCTL_UNAVAILABLE = CheckInfo(
        9,
        "lnetctl is not available on this node, so the LNet transport and EFA probes were skipped "
        "(the Lustre client may not be installed).",
    )
    EFA_NOT_SUPPORTED_ON_OS = CheckInfo(
        10,
        "EFA-for-Lustre is not supported on this OS ({}), so the EFA probes were skipped. EFA-for-Lustre "
        "requires Amazon Linux 2023, RHEL 9.5+, or Ubuntu 22.04+.",
    )

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that FsxLustre filesystems are installed, mounted, reachable, and riding EFA."

    def should_run(self, context: Context) -> bool:
        """Run only when a FsxLustre filesystem is configured."""
        return _has_lustre(context)

    def run(self, context: Context) -> Result:
        """Run every Lustre probe in isolation, accumulate findings, and derive the aggregate Result."""
        errors: List[CheckError] = []
        warnings: List[CheckWarning] = []
        infos: List[CheckInfo] = []

        # lnetctl net show -v is fetched once here; both the LNet and EFA probes read this snapshot.
        lnet = self._lnet_snapshot()

        probes = (
            ("lustre client", lambda: self._probe_client(context, errors, infos)),
            ("mount presence", lambda: self._probe_mounts(context, errors)),
            ("filesystem reachability", lambda: self._probe_reachable(context, errors)),
            ("lnet transport", lambda: self._probe_lnet(lnet, errors, warnings, infos)),
            ("efa mount", lambda: self._probe_efa(context, lnet, errors, warnings, infos)),
        )
        for label, probe in probes:
            run_probe(label, probe, errors)

        return Result.from_findings(self, errors=errors, warnings=warnings, infos=infos)

    # --- Probes -------------------------------------------------------------------------------

    def _lnet_snapshot(self) -> _LnetSnapshot:
        """Fetch ``lnetctl net show -v`` once, returning a snapshot both LNet/EFA probes consume.

        ``-v`` is used so per-NI statistics and health values are available; the non-verbose fields (net
        type, nid, interfaces) are a subset, so one verbose call serves both probes.
        """
        # Check the binary is present before running it: lnetctl is absent when the Lustre client is not
        # installed, and running a missing binary would raise out of this call (which is outside the
        # per-probe isolation loop) and sink the whole check. This gate covers both the LNet and EFA
        # probes, since both only reach lnetctl through this snapshot.
        if shutil.which("lnetctl") is None:
            return _LnetSnapshot(timed_out=False, unavailable=True)
        result = time_command(["lnetctl", "net", "show", "-v"], timeout=FSX_LNET_SHOW_TIMEOUT_SECONDS)
        if result.timed_out:
            return _LnetSnapshot(timed_out=True)
        nets = lustre.parse_lnet_net_show(result.stdout) if result.returncode == 0 else []
        return _LnetSnapshot(timed_out=False, nets=nets)

    def _probe_client(self, context: Context, errors: List[CheckError], infos: List[CheckInfo]) -> None:
        """Fail when the Lustre kernel modules are unavailable, or available but not loaded.

        The kernel module is the authoritative signal: Lustre can only mount if the ``lustre`` and
        ``lnet`` modules are available for the running kernel. We check ``modinfo`` rather than a package
        name (names vary by OS/install source, and a package can be present while the module is not built
        for the current kernel -- in which case Lustre still cannot mount).
        """
        module_available = all(kernel_module.kernel_module_available(m) for m in lustre.LUSTRE_KERNEL_MODULES)
        if not module_available:
            # An unavailable module cannot be loaded, so reporting "not loaded" too would just restate the
            # same root cause. Only inspect the load state when the modules are actually available.
            errors.append(self.NOT_INSTALLED.format(kernel_module.kernel_release() or "unknown"))
        else:
            not_loaded = [m for m in lustre.LUSTRE_KERNEL_MODULES if not kernel_module.kernel_module_loaded(m)]
            if not_loaded:
                errors.append(self.MODULES_NOT_LOADED.format(", ".join(not_loaded)))

        version = lustre.lustre_client_version()
        if version:
            infos.append(self.CLIENT_VERSION.format(version))
            # The client-version floor is per base_os (rhel8/rocky8 ship 2.12, others 2.15); an unknown/
            # missing base_os uses the default. version_at_least is tri-state: True (>= floor), False
            # (definitely below -> FAILURE), or None (version present but unparseable). We do not mask the
            # None case: rather than silently skip it, we report a CHECK_ERROR (reserved E0) saying the
            # floor could not be evaluated -- distinct from a definite too-old FAILURE.
            minimum = LUSTRE_CLIENT_MIN_VERSION_BY_OS.get(_base_os(context), LUSTRE_CLIENT_MIN_VERSION_DEFAULT)
            at_least = kernel_module.version_at_least(version, minimum)
            if at_least is None:
                errors.append(self.CLIENT_VERSION_UNDETERMINABLE.format(version, minimum))
            elif at_least is False:
                errors.append(self.CLIENT_TOO_OLD.format(version, minimum))

    def _probe_mounts(self, context: Context, errors: List[CheckError]) -> None:
        """Fail listing any configured Lustre mount absent from /proc/mounts (a non-hanging check)."""
        mounts = shared_storage.read_mounts()
        for configured in shared_storage.lustre_mounts(context):
            if not shared_storage.is_mounted(mounts, configured.mount_dir, shared_storage.LUSTRE_FS_TYPE):
                errors.append(self.NOT_MOUNTED.format(configured.mount_dir, configured.storage_type))

    def _probe_reachable(self, context: Context, errors: List[CheckError]) -> None:
        """Aggregate ``lfs df -h`` per Lustre mount, classifying a hang, an error, or a down target."""
        for configured in shared_storage.lustre_mounts(context):
            errors.extend(self._probe_mount(configured.mount_dir))

    def _probe_mount(self, mount_dir: str) -> List[CheckError]:
        """Return the CheckErrors for one Lustre mount: empty when it is reachable and all targets are up."""
        result = time_command(["lfs", "df", "-h", mount_dir], timeout=FSX_LFS_DF_TIMEOUT_SECONDS)
        if result.timed_out:
            return [self.LFS_DF_TIMED_OUT.format(mount_dir, FSX_LFS_DF_TIMEOUT_SECONDS)]
        if result.returncode != 0:
            return [self.LFS_DF_FAILED.format(mount_dir, result.stderr.strip())]

        return [
            self.TARGET_UNAVAILABLE.format(target.uuid, mount_dir)
            for target in lustre.unavailable_targets(result.stdout)
        ]

    def _probe_lnet(
        self,
        lnet: _LnetSnapshot,
        errors: List[CheckError],
        warnings: List[CheckWarning],
        infos: List[CheckInfo],
    ) -> None:
        """Report the active LNDs; fail when LNet is unresponsive or unconfigured while Lustre is present.

        Parses ``lnetctl net show`` and reports which LNDs are active (``tcp``, ``efa``, ``o2ib``). A node
        still carrying an ``@efa`` net after an intended TCP cutover -- or, the reverse, no LNet at all
        while a Lustre filesystem is mounted -- is immediately visible. Read-only; never mutates LNet.
        """
        if lnet.timed_out:
            errors.append(self.LNETCTL_TIMED_OUT.format(FSX_LNET_SHOW_TIMEOUT_SECONDS))
            return
        if lnet.unavailable:
            # lnetctl is not installed -- report it as info and skip; not a Lustre-health failure by itself.
            infos.append(self.LNETCTL_UNAVAILABLE)
            return

        active = lustre.active_lnds(lnet.nets)
        if not active:
            errors.append(self.LNET_NOT_CONFIGURED)
        else:
            infos.append(self.ACTIVE_LNDS.format(", ".join(active)))
            warnings.extend(self._health_warnings(lnet.nets))

    def _probe_efa(
        self,
        context: Context,
        lnet: _LnetSnapshot,
        errors: List[CheckError],
        warnings: List[CheckWarning],
        infos: List[CheckInfo],
    ) -> None:
        """Detect the EFA-for-Lustre root causes, after verifying the EFA prerequisites are in place.

        Acts only when EFA-for-Lustre is *expected* on this node. "Expected" is signalled by EITHER an
        ``@efa`` LNet net being configured OR the ``configure-efa-fsx-lustre-client`` systemd service being
        installed on this node. The service is essential to the gate: if ``kefalnd`` failed to load, no
        ``@efa`` net is ever added, so gating on the ``@efa`` net alone would skip the very node the
        ``kefalnd`` check exists to catch -- the service (installed by the setup script, independent of
        whether kefalnd loaded) is the node-local "EFA was set up here" signal that survives that failure.
        We deliberately do not infer "expected" from the cluster config's OnNodeStart custom actions: the
        config carries the actions for every node type, and mapping those back to *this* node is unreliable.

        When expected, it first verifies the prerequisites the official FSx EFA-Lustre client setup
        enforces before configuring EFA -- the ``kefalnd`` module (that setup's own definition of "the
        client supports EFA"), the EFA driver version, and on the p6+ families the kefalnd version. A
        missing ``kefalnd`` is reported (``KEFALND_MISSING``) and short-circuits the rest: without it there
        can be no working ``@efa`` net, so the follow-on probes would add nothing. Then it reports the
        systemd service state and, when a live ``@efa`` net exists, automates the FSx tutorial's "Validate
        FSx with EFA is working" commands (``lnetctl net show --net efa -v``, ``lnetctl ping ...@efa``), to
        name -- not fix -- the failures. Read-only: never re-binds devices or edits the security group.
        """
        if lnet.timed_out or lnet.unavailable:
            # The LNet probe already reported the hang / missing lnetctl; there is nothing to inspect here.
            return
        base_os = _base_os(context)
        if base_os in EFA_LUSTRE_UNSUPPORTED_OSES:
            # EFA-for-Lustre is not supported on this OS (e.g. rhel8/rocky8), so none of the EFA
            # prerequisites/data-path probes apply here. Report why and skip.
            infos.append(self.EFA_NOT_SUPPORTED_ON_OS.format(base_os))
            return
        efa_net = lustre.lnet_net(lnet.nets, EFA_LNET_NET)
        # Query the service once (like the shared lnet snapshot) and reuse it for both the gate and the
        # service-state report. This is the signal that survives a kefalnd load failure (which leaves no
        # @efa net), so it -- not the @efa net alone -- decides whether EFA is expected on this node.
        service_installed = services.systemd_unit_exists(EFA_LUSTRE_SYSTEMD_SERVICE)
        if efa_net is None and not service_installed:
            # Neither an @efa net nor the EFA-Lustre service on this node: EFA is not expected; nothing to check.
            return

        # Prerequisites first (mirrors the official setup's ordering), BEFORE bailing on a missing @efa net:
        # a missing kefalnd is exactly why the @efa net would be absent, and it is the root cause to report.
        if not self._probe_efa_prerequisites(context, errors, infos):
            return

        # The systemd service is how this delivery vehicle persists the EFA/LNet config across reboots.
        self._probe_efa_service(service_installed, errors, infos)

        if efa_net is None:
            # The service is installed but no @efa net came up (e.g. the config service failed): the
            # prerequisite/service findings above localize why. There is no live net to probe for
            # devices/traffic, so stop here.
            return

        bound = lustre.lnet_bound_interfaces(lnet.nets, EFA_LNET_NET)
        available = efa.efa_device_count()
        expected = efa.expected_bound_device_count(context.instance_type, available)
        # Note (once) that the expected binding is instance-type-specific per the FSx guide, so an operator
        # reading the device-count findings knows "fewer than all bound" can be intentional.
        infos.append(self.EFA_BINDING_REFERENCE)
        if available == 0:
            errors.append(self.NO_EFA_DEVICES.format(EFA_INFINIBAND_SYSFS))
        elif not bound:
            # EFA devices exist but none are bound at all: Lustre cannot ride EFA on any family.
            errors.append(self.NO_DEVICES_BOUND.format(available))
        elif expected is not None and len(bound) < expected:
            # We know how many this instance type should bind, and fewer are bound -- a genuine shortfall
            # (e.g. the p6-b300 "bind all" family with only a subset bound). Compared against the expected
            # count, NOT the raw device count, so families that bind a subset by design do not false-fire.
            errors.append(self.UNDERBOUND_DEVICES.format(len(bound), expected, context.instance_type))
        else:
            # All expected devices are bound, or we have no static expectation for this instance type
            # (unknown/dynamic selection) -- report the count as context and pass.
            infos.append(self.BOUND_DEVICES.format(len(bound), available))

        warnings.extend(self._traffic_warnings(efa_net))
        errors.extend(self._efa_ping_errors(lnet.nets))
        # _tcp_fallback_warnings is deliberately not called: current_connection reads @tcp on a healthy EFA
        # client, so it would warn on every node. See its docstring.

    def _probe_efa_prerequisites(self, context: Context, errors: List[CheckError], infos: List[CheckInfo]) -> bool:
        """Verify the EFA-for-Lustre client prerequisites; return whether kefalnd is present.

        A False return (kefalnd missing) means the client fundamentally cannot ride EFA, so the caller
        skips the data-path probes. The EFA driver and (on the p6+ families) kefalnd version floors are
        reported here too. A version/family that cannot be determined -- an unparseable module version, or
        (for the p6+ gate) an instance type IMDS could not report -- is not masked: it is surfaced as a
        CHECK_ERROR (reserved E0) noting the check could not be evaluated, distinct from a definite too-old
        FAILURE.
        """
        if not efa.efa_kefalnd_supported():
            errors.append(self.KEFALND_MISSING)
            return False

        self._check_efa_driver_version(errors, infos)
        self._check_kefalnd_version(context, errors, infos)
        return True

    def _check_efa_driver_version(self, errors: List[CheckError], infos: List[CheckInfo]) -> None:
        """Report the EFA driver version; flag definitely-too-old as FAILURE and undeterminable as E0."""
        driver_version = efa.efa_driver_version()
        if not driver_version:
            errors.append(self.EFA_DRIVER_VERSION_UNDETERMINABLE.format(MIN_EFA_DRIVER_VERSION))
            return
        infos.append(self.EFA_DRIVER_VERSION.format(driver_version))
        at_least = kernel_module.version_at_least(driver_version, MIN_EFA_DRIVER_VERSION)
        if at_least is None:
            # Present but unparseable -- the floor could not be evaluated; report it, do not assume too-old.
            errors.append(self.EFA_DRIVER_VERSION_UNDETERMINABLE.format(MIN_EFA_DRIVER_VERSION))
        elif at_least is False:
            errors.append(self.EFA_DRIVER_TOO_OLD.format(driver_version, MIN_EFA_DRIVER_VERSION))

    def _check_kefalnd_version(self, context: Context, errors: List[CheckError], infos: List[CheckInfo]) -> None:
        """Report the kefalnd version and, on the p6+ families only, flag it when definitely below the floor.

        The p6+ gate needs the instance type. When it is unknown (IMDS could not report it at startup),
        is_p6plus_instance returns None: we cannot tell whether the p6+ floor applies, so we surface a
        CHECK_ERROR (reserved E0) that the check could not be evaluated rather than silently passing.
        """
        kefalnd_version = efa.efa_kefalnd_version()
        if kefalnd_version:
            infos.append(self.KEFALND_VERSION.format(kefalnd_version))

        p6plus = efa.is_p6plus_instance(context.instance_type)
        if p6plus is None:
            errors.append(self.INSTANCE_TYPE_UNDETERMINABLE.format(EFA_KEFALND_KERNEL_MODULE, MIN_KEFALND_VERSION_P6))
            return
        if not p6plus:
            # Known non-p6 family: the kefalnd version floor does not apply.
            return

        # p6+ family: the floor applies.
        if not kefalnd_version:
            errors.append(self.KEFALND_VERSION_UNDETERMINABLE.format(MIN_KEFALND_VERSION_P6))
            return
        at_least = kernel_module.version_at_least(kefalnd_version, MIN_KEFALND_VERSION_P6)
        if at_least is None:
            errors.append(self.KEFALND_VERSION_UNDETERMINABLE.format(MIN_KEFALND_VERSION_P6))
        elif at_least is False:
            errors.append(self.KEFALND_TOO_OLD.format(kefalnd_version, MIN_KEFALND_VERSION_P6, context.instance_type))

    def _probe_efa_service(self, service_installed: bool, errors: List[CheckError], infos: List[CheckInfo]) -> None:
        """Report the state of the ``configure-efa-fsx-lustre-client`` service that (re)configures LNet on boot.

        ``service_installed`` is passed in (already queried by the caller for the EFA-expected gate) to
        avoid a second ``systemctl`` call. Failed -> error (LNet was not configured for EFA); installed and
        not failed -> info; not installed -> info (LNet is configured at runtime by the bootstrap script
        rather than this service).
        """
        efa_service = EFA_LUSTRE_SYSTEMD_SERVICE
        if not service_installed:
            infos.append(self.EFA_SERVICE_ABSENT.format(efa_service))
        elif services.systemd_unit_failed(efa_service):
            errors.append(self.EFA_SERVICE_FAILED.format(efa_service, efa_service))
        else:
            infos.append(self.EFA_SERVICE_ACTIVE.format(efa_service))

    def _health_warnings(self, nets) -> List[CheckWarning]:
        """Return a warning per NI whose health value has decayed below the healthy maximum (1000)."""
        warnings: List[CheckWarning] = []
        for net in nets:
            for ni in net.local_nis:
                if ni.health_value is not None and ni.health_value < 1000:
                    warnings.append(self.HEALTH_DEGRADED.format(ni.nid, net.net_type, ni.health_value))
        return warnings

    def _traffic_warnings(self, efa_net) -> List[CheckWarning]:
        """Return a warning per EFA NI that reports zero send and zero receive traffic.

        This is a single-shot counter snapshot, so zero traffic is expected on an idle or freshly-booted
        node -- the warning is worded as "no traffic yet" and stays a non-fatal warning for that reason.
        """
        warnings: List[CheckWarning] = []
        for ni in efa_net.local_nis:
            if ni.send_count == 0 and ni.recv_count == 0:
                warnings.append(self.NO_TRAFFIC.format(ni.nid))
        return warnings

    def _efa_ping_errors(self, nets) -> List[CheckError]:
        """Ping an @efa peer over EFA (the tutorial's own validation); error when the data path fails.

        Automates ``lnetctl ping --source <local>@efa <peer>@efa``. Discovers a local @efa nid and a peer
        @efa nid from ``lnetctl``; when either is unavailable there is nothing to ping, so the probe is
        skipped (a missing peer/local nid is not itself proof the data path is broken).
        """
        local = lustre.local_nids(nets, EFA_LNET_NET)
        if not local:
            return []
        peer_nid = lustre.efa_peer_nid()
        if peer_nid is None:
            return []
        source = local[0]
        if not lustre.efa_ping_works(source, peer_nid):
            return [self.EFA_PING_FAILED.format(source, peer_nid)]
        return []

    def _tcp_fallback_warnings(self, nets) -> List[CheckWarning]:
        """Return a warning per target connected over @tcp while an @efa net is configured. NOT EXECUTED.

        Kept for reference but no longer called from ``_probe_efa``: ``current_connection`` reads @tcp on a
        healthy EFA client, because FSx documents the mount target as ``<dns_name>@tcp`` for EFA-enabled
        file systems too and LNet Multi-Rail selects the rail below ptlrpc, where the import cannot see it.
        The warning would therefore fire on every healthy node. The signal that does distinguish the two is
        a per-NI ``send_count``/``recv_count`` delta measured across filesystem I/O.
        """
        if lustre.lnet_net(nets, EFA_LNET_NET) is None:
            return []
        result = time_command(
            ["lctl", "get_param", "osc.*.import", "mdc.*.import"], timeout=FSX_OST_QUERY_TIMEOUT_SECONDS
        )
        if result.timed_out or result.returncode != 0:
            return []
        return [
            self.TCP_FALLBACK.format(state.target or state.param)
            for state in lustre.parse_lctl_import(result.stdout)
            if state.connected_over == "tcp"
        ]


class FsxTargetsAreReachable(Check):
    """Opt-in deep check pinpointing an unreachable OST/MDT -- a common cause of a hung directory listing.

    NOT REGISTERED: kept for reference but left out of ``DEFAULT_REGISTRY``, so nothing here runs. Its
    import-state findings rest on ``current_connection``/``failover_nids``, which do not carry the meaning
    they were read with (see :meth:`LustreFilesystem._tcp_fallback_warnings`), and its ``lfs check servers``
    parsing reports a phantom target for the bare ``lfs check: error:`` line real output contains.

    Runs ``lfs check servers`` (the per-target reachability diagnostic) via ``time_command`` and inspects
    client-side import state (``lctl get_param osc.*.import`` / ``mdc.*.import``). Because probing
    individual targets is heavier and can itself block, this check is gated behind ``approval_required`` so
    it runs only when the operator opts in (or passes ``--yes``). It is kept separate from
    :class:`LustreFilesystem` because the approval gate is per-check.
    """

    LFS_CHECK_TIMED_OUT = CheckError(
        1,
        "lfs check servers did not return within {}s -- the client is blocked on an unreachable target.",
    )
    LFS_CHECK_FAILED = CheckError(2, "lfs check servers failed: {}")
    TARGET_UNREACHABLE = CheckError(3, "target {} is unreachable (lfs check servers: {}).")
    IMPORT_NOT_FULL = CheckError(4, "target {} import state is {} (not {}) -- the client is not fully connected.")
    FAILOVER_PINNED = CheckInfo(
        1,
        "target {} current_connection {} equals its failover_nids -- no distinct failover NID "
        "(a primary-server failure has no real failover).",
    )

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Deep-probe each FsxLustre OST/MDT for reachability (lfs check servers + import state)."

    def should_run(self, context: Context) -> bool:
        """Run only when a FsxLustre filesystem is configured."""
        return _has_lustre(context)

    def approval_required(self, context: Context) -> bool:
        """Require confirmation: probing every target is heavier and can itself block."""
        return True

    def run(self, context: Context) -> Result:
        """Aggregate ``lfs check servers`` and import-state findings across every Lustre target."""
        errors: List[CheckError] = []
        infos: List[CheckInfo] = []

        errors.extend(self._check_servers())
        import_errors, import_infos = self._check_imports()
        errors.extend(import_errors)
        infos.extend(import_infos)

        return Result.from_findings(self, errors=errors, infos=infos)

    def _check_servers(self) -> List[CheckError]:
        """Return CheckErrors from ``lfs check servers``: a hang, a command failure, or per-target errors."""
        result = time_command(["lfs", "check", "servers"], timeout=FSX_LFS_CHECK_TIMEOUT_SECONDS)
        if result.timed_out:
            return [self.LFS_CHECK_TIMED_OUT.format(FSX_LFS_CHECK_TIMEOUT_SECONDS)]
        if result.returncode != 0:
            return [self.LFS_CHECK_FAILED.format(result.stderr.strip())]
        return [
            self.TARGET_UNREACHABLE.format(server.target, server.detail)
            for server in lustre.unreachable_servers(result.stdout)
        ]

    def _check_imports(self):
        """Return (errors, infos) from client-side import state: non-FULL targets and failover pinning."""
        errors: List[CheckError] = []
        infos: List[CheckInfo] = []
        result = time_command(
            ["lctl", "get_param", "osc.*.import", "mdc.*.import"], timeout=FSX_OST_QUERY_TIMEOUT_SECONDS
        )
        if result.timed_out or result.returncode != 0:
            return errors, infos
        for state in lustre.parse_lctl_import(result.stdout):
            name = state.target or state.param
            if not state.healthy:
                errors.append(self.IMPORT_NOT_FULL.format(name, state.state or "unknown", HEALTHY_TARGET_STATE))
            if state.current_connection and state.failover_nids == [state.current_connection]:
                infos.append(self.FAILOVER_PINNED.format(name, state.current_connection))
        return errors, infos
