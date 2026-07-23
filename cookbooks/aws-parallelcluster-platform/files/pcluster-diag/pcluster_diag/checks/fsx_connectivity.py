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
queries (package/kernel-module presence, reading ``/proc/mounts``) go through ``run_command``.

Three checks, in execution order:

- ``LustreClientIsInstalled`` verifies the node can actually speak Lustre (package + kernel modules)
  before connectivity is probed, so a broken client is reported as its own root cause.
- ``FsxMountsArePresent`` is a cheap, non-hanging pre-flight confirming each configured Lustre mount is
  actually mounted, so a "not mounted" problem is not misreported downstream as "unreachable".
- ``FsxFilesystemsAreReachable`` runs ``lfs df -h`` per mount (the FSx-team-recommended first-line
  command) and classifies a hang, an error, or a down target.

All three run on every node type that has a FsxLustre mount configured, and skip (SKIPPED_NOT_APPLICABLE)
when the cluster configures no FsxLustre filesystem. Every probe is read-only.
"""

import logging
from typing import List

from pcluster_diag.core.constants import FSX_LFS_DF_TIMEOUT_SECONDS, LUSTRE_CLIENT_PACKAGES
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context
from pcluster_diag.models.finding import CheckError, CheckInfo, CheckWarning
from pcluster_diag.models.result import Result
from pcluster_diag.util import lustre, packages, shared_storage
from pcluster_diag.util.shell import time_command

logger = logging.getLogger(__name__)


def _has_lustre(context: Context) -> bool:
    """Return whether the cluster configuration declares at least one FsxLustre mount."""
    return bool(shared_storage.lustre_mounts(context))


class LustreClientIsInstalled(Check):
    """Verify the Lustre client (package + kernel modules) is present so the node can speak Lustre."""

    PACKAGE_MISSING = CheckError(
        1, "Lustre client package is not installed though a FsxLustre filesystem is configured."
    )
    MODULE_UNAVAILABLE = CheckError(
        2,
        "Lustre kernel module is not available for kernel {} (client may not have rebuilt after a kernel update).",
    )
    MODULES_NOT_LOADED = CheckWarning(1, "lustre/lnet kernel modules are not loaded.")
    CLIENT_VERSION = CheckInfo(2, "Lustre client version: {}.")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that the Lustre client package and kernel modules are installed."

    def should_run(self, context: Context) -> bool:
        """Run only when a FsxLustre filesystem is configured."""
        return _has_lustre(context)

    def run(self, context: Context) -> Result:
        """Fail when the client package or a kernel module is missing; warn when modules are not loaded."""
        errors: List[CheckError] = []
        warnings: List[CheckWarning] = []
        infos: List[CheckInfo] = []

        if not lustre.lustre_client_installed(LUSTRE_CLIENT_PACKAGES):
            errors.append(self.PACKAGE_MISSING)

        unavailable = [m for m in lustre.LUSTRE_KERNEL_MODULES if not packages.kernel_module_available(m)]
        if unavailable:
            errors.append(self.MODULE_UNAVAILABLE.format(packages.kernel_release() or "unknown"))

        not_loaded = [module for module in lustre.LUSTRE_KERNEL_MODULES if not packages.kernel_module_loaded(module)]
        if not_loaded:
            warnings.append(self.MODULES_NOT_LOADED)

        version = lustre.lustre_client_version()
        if version:
            infos.append(self.CLIENT_VERSION.format(version))

        return Result.from_findings(self, errors=errors, warnings=warnings, infos=infos)


class FsxMountsArePresent(Check):
    """Verify each configured FsxLustre MountDir is actually mounted (a non-hanging mount-table check)."""

    NOT_MOUNTED = CheckError(1, "'{}' ({}) is configured but not mounted.")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that configured FsxLustre filesystems are mounted."

    def should_run(self, context: Context) -> bool:
        """Run only when a FsxLustre filesystem is configured."""
        return _has_lustre(context)

    def run(self, context: Context) -> Result:
        """Pass when every configured Lustre mount is present in /proc/mounts; fail listing those absent."""
        mounts = shared_storage.read_mounts()
        errors: List[CheckError] = []
        for configured in shared_storage.lustre_mounts(context):
            if not shared_storage.is_mounted(mounts, configured.mount_dir, shared_storage.LUSTRE_FS_TYPE):
                errors.append(self.NOT_MOUNTED.format(configured.mount_dir, configured.storage_type))
        return Result.from_findings(self, errors=errors)


class FsxFilesystemsAreReachable(Check):
    """Verify each Lustre mount answers ``lfs df -h`` (server/OST reachability) without hanging."""

    LFS_DF_TIMED_OUT = CheckError(
        1,
        "lfs df -h on '{}' did not return within {}s -- the filesystem is hanging (server/OST unreachable).",
    )
    LFS_DF_FAILED = CheckError(2, "lfs df -h on '{}' failed: {}")
    TARGET_UNAVAILABLE = CheckError(3, "target {} on '{}' is not available (possible OST/MDT down).")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that configured FsxLustre filesystems are reachable via lfs df."

    def should_run(self, context: Context) -> bool:
        """Run only when a FsxLustre filesystem is configured."""
        return _has_lustre(context)

    def run(self, context: Context) -> Result:
        """Aggregate ``lfs df -h`` per Lustre mount, classifying a hang, an error, or a down target."""
        errors: List[CheckError] = []
        for configured in shared_storage.lustre_mounts(context):
            errors.extend(self._probe_mount(configured.mount_dir))
        return Result.from_findings(self, errors=errors)

    def _probe_mount(self, mount_dir: str) -> List[CheckError]:
        """Return the CheckErrors for one Lustre mount: empty when it is reachable and all targets are up."""
        timed = time_command(["lfs", "df", "-h", mount_dir], timeout=FSX_LFS_DF_TIMEOUT_SECONDS)
        if timed.timed_out:
            return [self.LFS_DF_TIMED_OUT.format(mount_dir, FSX_LFS_DF_TIMEOUT_SECONDS)]
        if timed.returncode != 0:
            return [self.LFS_DF_FAILED.format(mount_dir, timed.stderr.strip())]

        return [
            self.TARGET_UNAVAILABLE.format(target.uuid, mount_dir)
            for target in lustre.unavailable_targets(timed.stdout)
        ]
