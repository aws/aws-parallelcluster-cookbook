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

"""Kernel-module and kernel probing.

Thin wrappers over ``modinfo``/``lsmod`` (kernel module availability and load state) and ``uname``
(running kernel release). These are used by the Lustre client checks but contain nothing
Lustre-specific. Every external command is routed through :mod:`pcluster_diag.util.shell`; a missing
binary is treated as a negative answer, never an exception.
"""

import logging
from typing import List, Optional

from pcluster_diag.util.shell import run_command

logger = logging.getLogger(__name__)


def _command_succeeded(command: List[str]) -> bool:
    """Run ``command`` and return whether it exited 0; a missing binary counts as failure."""
    try:
        return run_command(command).returncode == 0
    except OSError as error:
        logger.warning("Could not run %s: %s", command, error)
        return False


def kernel_module_available(module: str) -> bool:
    """Return whether ``module`` is available for the running kernel per ``modinfo``."""
    return _command_succeeded(["modinfo", module])


def kernel_module_loaded(module: str) -> bool:
    """Return whether ``module`` is currently loaded per ``lsmod`` (False when lsmod is unavailable)."""
    try:
        result = run_command(["lsmod"])
    except OSError as error:
        logger.warning("Could not run lsmod: %s", error)
        return False
    if result.returncode != 0:
        return False
    for line in result.stdout.splitlines():
        fields = line.split()
        if fields and fields[0] == module:
            return True
    return False


def kernel_release() -> Optional[str]:
    """Return the running kernel release (``uname -r``), or None when it cannot be determined."""
    try:
        result = run_command(["uname", "-r"])
    except OSError as error:
        logger.warning("Could not run uname: %s", error)
        return None
    return result.stdout.strip() if result.returncode == 0 else None


def module_version(module: str) -> Optional[str]:
    """Return a kernel module's version (``modinfo -F version <module>``), or None when unavailable."""
    try:
        result = run_command(["modinfo", "-F", "version", module])
    except OSError as error:
        logger.warning("Could not run modinfo to read the %s version: %s", module, error)
        return None
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None
