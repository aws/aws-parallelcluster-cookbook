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
(running kernel release), plus a small dotted-version comparison for module versions. Every external
command is routed through the shell helper; a missing binary is treated as a negative answer, never an
exception.
"""

import logging
import re
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


def version_at_least(actual: Optional[str], minimum: str) -> Optional[bool]:
    """Return whether dotted version ``actual`` is >= ``minimum``, or ``None`` when it cannot be determined.

    Returns True/False for a comparable ``actual``, and ``None`` when ``actual`` is missing or unparseable
    (rather than conflating "could not determine the version" with "below the minimum"). This lets the
    caller surface an unparseable version as an undeterminable check instead of a false below-minimum
    result. Only the leading dotted-numeric prefix is compared (e.g. ``2.15.6-1.fsx23`` -> ``[2, 15, 6]``).
    """
    parsed_actual = _numeric_version(actual)
    parsed_min = _numeric_version(minimum)
    if parsed_actual is None or parsed_min is None:
        return None
    length = max(len(parsed_actual), len(parsed_min))
    parsed_actual += [0] * (length - len(parsed_actual))
    parsed_min += [0] * (length - len(parsed_min))
    return parsed_actual >= parsed_min


def _numeric_version(version: Optional[str]) -> Optional[List[int]]:
    """Return the leading dotted-numeric components of ``version`` (e.g. ``2.15.6-1`` -> ``[2, 15, 6]``)."""
    if not version:
        return None
    match = re.match(r"(\d+(?:\.\d+)*)", version.strip())
    if not match:
        return None
    return [int(part) for part in match.group(1).split(".")]
