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

"""Probes reading the installed version of the critical third-party software: Slurm, EFA and the NVIDIA stack.

Every probe returns None when the software is not installed or its version cannot be read; a missing binary or
file is never an exception.
"""

import logging
import os
import re
from pathlib import Path
from typing import List, Optional, Tuple

from pcluster_diag.core.constants import (
    CUDA_NVCC_PATH,
    EFA_INSTALLED_PACKAGES_PATH,
    GB200_PCI_DEVICE_ID,
    GDRCOPY_KERNEL_MODULE,
    GPU_3D_CONTROLLER_PCI_CLASS,
    INFINIBAND_CONTROLLER_PCI_CLASS,
    MELLANOX_PCI_VENDOR_ID,
    NV_FABRICMANAGER_PATH,
    NVIDIA_DRIVER_KERNEL_MODULE,
    NVIDIA_PCI_VENDOR_ID,
    NVSWITCH_BRIDGE_PCI_CLASS,
    PCI_DEVICES_SYSFS,
)
from pcluster_diag.util import kernel_module
from pcluster_diag.util.shell import run_command

logger = logging.getLogger(__name__)

# ``sinfo --version`` prints e.g. ``slurm 25.11.8``.
_SLURM_VERSION_PATTERN = re.compile(r"^slurm\s+(\S+)", re.MULTILINE)
# The EFA installer records its version in /opt/amazon/efa_installed_packages, e.g. ``EFA installer version: 1.49.0``.
_EFA_INSTALLER_VERSION_PATTERN = re.compile(r"EFA installer version:\s*(\S+)")
# ``nvcc --version`` prints e.g. ``Cuda compilation tools, release 13.2, V13.2.78``.
_CUDA_RELEASE_PATTERN = re.compile(r"release\s+(\d+(?:\.\d+)*)")
# ``nv-fabricmanager --version`` prints e.g. ``Fabric Manager version is : 595.71.05``.
_FABRIC_MANAGER_VERSION_PATTERN = re.compile(r"version is\s*:\s*(\S+)")


def slurm_version(install_dir: str) -> Optional[str]:
    """Return the version of the Slurm installed in ``install_dir`` (``sinfo --version``), or None."""
    return _command_output_match(["{}/bin/sinfo".format(install_dir.rstrip("/")), "--version"], _SLURM_VERSION_PATTERN)


def efa_installer_version() -> Optional[str]:
    """Return the version of the EFA installer that installed EFA on the node, or None."""
    try:
        content = Path(EFA_INSTALLED_PACKAGES_PATH).read_text(encoding="utf-8")
    except OSError as error:
        logger.warning("Could not read %s: %s", EFA_INSTALLED_PACKAGES_PATH, error)
        return None
    match = _EFA_INSTALLER_VERSION_PATTERN.search(content)
    return match.group(1) if match else None


def nvidia_driver_version() -> Optional[str]:
    """Return the version of the NVIDIA driver kernel module available for the running kernel, or None."""
    return kernel_module.module_version(NVIDIA_DRIVER_KERNEL_MODULE)


def cuda_version() -> Optional[str]:
    """Return the release of the CUDA toolkit behind the ``/usr/local/cuda`` symlink (``nvcc --version``), or None."""
    return _command_output_match([CUDA_NVCC_PATH, "--version"], _CUDA_RELEASE_PATTERN)


def gdrcopy_version() -> Optional[str]:
    """Return the version of the GDRCopy kernel module (``gdrdrv``), or None."""
    return kernel_module.module_version(GDRCOPY_KERNEL_MODULE)


def fabric_manager_version() -> Optional[str]:
    """Return the version of NVIDIA Fabric Manager (``nv-fabricmanager --version``), or None."""
    return _command_output_match([NV_FABRICMANAGER_PATH, "--version"], _FABRIC_MANAGER_VERSION_PATTERN)


def has_nvidia_gpu() -> bool:
    """Return whether the instance has an NVIDIA PCI device, as the cookbook's ``graphic_instance?`` does."""
    return any(vendor == NVIDIA_PCI_VENDOR_ID for vendor, _, _ in _pci_devices())


def fabric_manager_expected() -> bool:
    """Return whether the cookbook runs NVIDIA Fabric Manager on the instance.

    It does on instances with more than one GPU and more than one NVSwitch bridge or InfiniBand controller (the
    NVSwitch systems), except GB200 (cookbook ``enable_fabric_manager? && !is_gb200_node?``).
    """
    devices = _pci_devices()

    def count(vendor_id: str, class_id: str = "", device_id: str = "") -> int:
        return sum(
            1
            for vendor, device, pci_class in devices
            if vendor == vendor_id and pci_class.startswith(class_id) and device.startswith(device_id)
        )

    gpus = count(NVIDIA_PCI_VENDOR_ID, GPU_3D_CONTROLLER_PCI_CLASS)
    nvswitches = count(NVIDIA_PCI_VENDOR_ID, NVSWITCH_BRIDGE_PCI_CLASS)
    infiniband_controllers = count(MELLANOX_PCI_VENDOR_ID, INFINIBAND_CONTROLLER_PCI_CLASS)
    gb200 = count(NVIDIA_PCI_VENDOR_ID, device_id=GB200_PCI_DEVICE_ID)
    return gpus > 1 and (nvswitches > 1 or infiniband_controllers > 1) and gb200 <= 1


def version_parts(version: str) -> List[str]:
    """Return the components of ``version``, split on dots and dashes.

    ParallelCluster writes some versions with dashes (Slurm ``25-11-8-1``) and the software reports them with dots
    (``25.11.8``), so both separators split.
    """
    return re.split(r"[.-]", version.strip())


def versions_match(installed: str, expected: str) -> bool:
    """Return whether ``installed`` and ``expected`` are equal on the components of the shorter of the two.

    The software reports its version with less or more components than ParallelCluster records (CUDA ``13.2`` for
    ``13.2.2``, Slurm ``25.11.8`` for ``25-11-8-1``). Numeric components are compared as numbers, so ``595.71.05``
    matches ``595.71.5``.
    """
    installed_parts, expected_parts = version_parts(installed), version_parts(expected)
    count = min(len(installed_parts), len(expected_parts))
    return [_comparable(part) for part in installed_parts[:count]] == [
        _comparable(part) for part in expected_parts[:count]
    ]


def _comparable(part: str):
    """Return ``part`` as an int when it is numeric, else as is."""
    return int(part) if part.isdigit() else part


def _pci_devices() -> List[Tuple[str, str, str]]:
    """Return the (vendor, device, class) ids of the PCI devices, e.g. ("0x10de", "0x2330", "0x030200")."""
    try:
        devices = os.listdir(PCI_DEVICES_SYSFS)
    except OSError as error:
        logger.warning("Could not list %s: %s", PCI_DEVICES_SYSFS, error)
        return []
    return [
        tuple(_pci_attribute(device, attribute) for attribute in ("vendor", "device", "class")) for device in devices
    ]


def _pci_attribute(device: str, attribute: str) -> str:
    """Return an id of the PCI ``device`` (e.g. its ``vendor``, ``0x10de``), or "" if it cannot be read."""
    try:
        return Path(PCI_DEVICES_SYSFS, device, attribute).read_text(encoding="utf-8").strip().lower()
    except OSError:
        return ""


def _command_output_match(command: List[str], pattern: "re.Pattern") -> Optional[str]:
    """Run ``command`` and return the first group ``pattern`` matches in its output, or None."""
    try:
        result = run_command(command)
    except OSError as error:
        logger.warning("Could not run %s: %s", command, error)
        return None
    if result.returncode != 0:
        return None
    match = pattern.search(result.stdout)
    return match.group(1) if match else None
