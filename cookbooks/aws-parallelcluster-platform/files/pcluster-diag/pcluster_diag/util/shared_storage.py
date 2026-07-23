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

"""Enumerating configured shared storage and reading the live mount table.

This module is storage-type agnostic: it discovers the shared-storage mounts declared in the cluster
configuration and reads the kernel mount table from ``/proc/mounts``. The Lustre-specific parsing lives
in :mod:`pcluster_diag.util.lustre`; system package/kernel-module probing lives in
:mod:`pcluster_diag.util.packages`. Every external command is routed through
:mod:`pcluster_diag.util.shell`; the queries here are fast and non-hanging.
"""

import logging
from dataclasses import dataclass
from typing import List, Optional

from pcluster_diag.core.constants import LUSTRE_STORAGE_TYPE
from pcluster_diag.models.context import Context
from pcluster_diag.util.shell import run_command

logger = logging.getLogger(__name__)

# The path to the kernel mount table. Reading it is a local, non-blocking query (kernel data, no
# filesystem I/O), so a stuck shared filesystem cannot wedge it.
PROC_MOUNTS_PATH = "/proc/mounts"

# The filesystem type a FsxLustre mount reports in /proc/mounts.
LUSTRE_FS_TYPE = "lustre"


@dataclass
class SharedStorageMount:
    """A shared-storage mount declared in the cluster configuration.

    Attributes:
        storage_type: The ``StorageType`` (e.g. ``FsxLustre``).
        mount_dir: The ``MountDir`` the filesystem is mounted at.
        name: The configured ``Name``, or None when absent.
        file_system_id: The FSx filesystem id (from ``FsxLustreSettings``), or None when absent.
    """

    storage_type: str
    mount_dir: str
    name: Optional[str] = None
    file_system_id: Optional[str] = None


@dataclass
class Mount:
    """A single entry parsed from ``/proc/mounts``.

    Attributes:
        source: The mount source (device or ``nid:/fsname`` for Lustre).
        mount_point: The directory the filesystem is mounted at.
        fs_type: The filesystem type (e.g. ``lustre``).
    """

    source: str
    mount_point: str
    fs_type: str


def shared_storage_mounts(context: Context) -> List[SharedStorageMount]:
    """Return the shared-storage mounts declared in ``context.cluster_config`` (empty when none)."""
    entries = (context.cluster_config or {}).get("SharedStorage") or []
    mounts: List[SharedStorageMount] = []
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        storage_type = entry.get("StorageType")
        mount_dir = entry.get("MountDir")
        if not storage_type or not mount_dir:
            continue
        settings = entry.get("FsxLustreSettings") or {}
        mounts.append(
            SharedStorageMount(
                storage_type=storage_type,
                mount_dir=mount_dir,
                name=entry.get("Name"),
                file_system_id=settings.get("FileSystemId"),
            )
        )
    return mounts


def lustre_mounts(context: Context) -> List[SharedStorageMount]:
    """Return only the ``FsxLustre`` shared-storage mounts declared in the cluster configuration."""
    return [mount for mount in shared_storage_mounts(context) if mount.storage_type == LUSTRE_STORAGE_TYPE]


def read_mounts() -> List[Mount]:
    """Return the live mount table parsed from ``/proc/mounts`` (empty when it cannot be read)."""
    try:
        result = run_command(["cat", PROC_MOUNTS_PATH])
    except OSError as error:
        logger.warning("Could not read %s: %s", PROC_MOUNTS_PATH, error)
        return []
    if result.returncode != 0:
        return []
    return parse_proc_mounts(result.stdout)


def parse_proc_mounts(output: str) -> List[Mount]:
    """Parse ``/proc/mounts`` content into ``Mount`` entries, skipping malformed lines."""
    mounts: List[Mount] = []
    for line in output.splitlines():
        fields = line.split()
        if len(fields) < 3:
            continue
        mounts.append(Mount(source=fields[0], mount_point=fields[1], fs_type=fields[2]))
    return mounts


def is_mounted(mounts: List[Mount], mount_dir: str, fs_type: str) -> bool:
    """Return whether ``mount_dir`` is present in ``mounts`` with the given ``fs_type``."""
    return any(mount.mount_point == mount_dir and mount.fs_type == fs_type for mount in mounts)
