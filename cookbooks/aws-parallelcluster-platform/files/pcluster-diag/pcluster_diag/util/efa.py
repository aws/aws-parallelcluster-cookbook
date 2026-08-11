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

"""EFA capability helpers: checks if EFA is present and usable on this instance.

The home for EFA-capability probing, so new EFA checks can build on it: the ``kefalnd`` module (the EFA
LND), the EFA driver and ``kefalnd`` module versions, the number of EFA devices the kernel exposes, and
whether the running instance is a p6+ family (which carries a higher ``kefalnd`` version floor).
"""

import logging
import os
from typing import Optional

from pcluster_diag.core.constants import (
    EFA_DRIVER_KERNEL_MODULE,
    EFA_EXPECTED_BOUND_DEVICES,
    EFA_INFINIBAND_SYSFS,
    EFA_KEFALND_KERNEL_MODULE,
    P6PLUS_INSTANCE_PREFIXES,
)
from pcluster_diag.util import kernel_module

logger = logging.getLogger(__name__)


def efa_kefalnd_supported() -> bool:
    """Return whether the Lustre client supports EFA, i.e. the ``kefalnd`` module is available.

    This mirrors the official FSx EFA-Lustre client setup's definition of EFA support (it verifies that
    ``modinfo kefalnd`` succeeds): a Lustre client with no ``kefalnd`` module cannot ride EFA no matter how
    LNet is configured.
    """
    return kernel_module.kernel_module_available(EFA_KEFALND_KERNEL_MODULE)


def efa_driver_version() -> Optional[str]:
    """Return the EFA driver kernel module version (``modinfo efa``), or None when unavailable."""
    return kernel_module.module_version(EFA_DRIVER_KERNEL_MODULE)


def efa_kefalnd_version() -> Optional[str]:
    """Return the ``kefalnd`` (EFA LND) kernel module version, or None when unavailable."""
    return kernel_module.module_version(EFA_KEFALND_KERNEL_MODULE)


def efa_device_count() -> int:
    """Return the number of EFA devices exposed under ``/sys/class/infiniband`` (0 when none).

    Only devices whose ``device/driver`` resolves to ``efa`` are counted. ``/sys/class/infiniband`` can
    also hold non-EFA RDMA devices, so a bare directory listing would over-count; filtering by driver
    mirrors how the official EFA-Lustre setup enumerates EFA interfaces.
    """
    try:
        entries = os.listdir(EFA_INFINIBAND_SYSFS)
    except OSError as error:
        logger.warning("Could not list %s: %s", EFA_INFINIBAND_SYSFS, error)
        return 0
    return sum(1 for name in entries if _is_efa_device(name))


def _is_efa_device(name: str) -> bool:
    """Return whether the ``/sys/class/infiniband`` entry ``name`` is backed by the ``efa`` driver."""
    driver_link = os.path.join(EFA_INFINIBAND_SYSFS, name, "device", "driver")
    try:
        return os.path.basename(os.path.realpath(driver_link)) == EFA_DRIVER_KERNEL_MODULE
    except OSError as error:
        logger.warning("Could not resolve the driver for %s: %s", name, error)
        return False


def expected_bound_device_count(instance_type: Optional[str], available: int) -> Optional[int]:
    """Return how many EFA devices the FSx-for-Lustre EFA setup binds on ``instance_type``, or None.

    Values come from EFA_EXPECTED_BOUND_DEVICES (mirroring the FSx-for-Lustre configure-efa-clients doc).
    ``available`` is the number of EFA devices actually present; the expected count is capped at it, so we
    never expect more than exist. Returns None when the instance type is unknown or not in the table -- the
    caller then makes no underbinding assertion beyond "at least one device must be bound".
    """
    if not instance_type:
        return None
    expected = EFA_EXPECTED_BOUND_DEVICES.get(instance_type)
    if expected is None:
        return None
    return min(expected, available)


def is_p6plus_instance(instance_type: Optional[str]) -> Optional[bool]:
    """Return whether ``instance_type`` is a p6+ family requiring the kefalnd version check.

    Returns True/False for a known instance type, and ``None`` when the instance type is unknown (e.g. IMDS
    could not be reached at context-build time). ``None`` lets the caller distinguish "known non-p6" (skip
    the p6-only kefalnd version floor cleanly) from "could not determine the family" (report that the check
    was skipped for lack of the instance type), rather than silently treating an unknown type as non-p6.

    The kefalnd minimum-version requirement applies only to the p6+ families (see
    ``P6PLUS_INSTANCE_PREFIXES``).
    """
    if not instance_type:
        return None
    return any(instance_type.startswith(prefix) for prefix in P6PLUS_INSTANCE_PREFIXES)
