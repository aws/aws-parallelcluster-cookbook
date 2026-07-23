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

"""Lustre-specific helpers: ``lfs df`` parsing and Lustre client detection.

This module holds only the genuinely Lustre-specific logic. Shared-storage enumeration and the
``/proc/mounts`` table live in :mod:`pcluster_diag.util.shared_storage`; the generic package and
kernel-module probes this module builds on live in :mod:`pcluster_diag.util.packages`.
"""

import re
from dataclasses import dataclass
from typing import List, Optional

from pcluster_diag.util import packages

# The out-of-tree kernel modules the Lustre client needs to speak Lustre.
LUSTRE_KERNEL_MODULES = ("lustre", "lnet")

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


def lustre_client_installed(client_packages) -> bool:
    """Return whether any of ``client_packages`` (the Lustre client package names) is installed."""
    return packages.package_installed(client_packages)


def lustre_client_version() -> Optional[str]:
    """Return the Lustre client version (from the ``lustre`` kernel module), or None when unavailable."""
    return packages.module_version("lustre")
