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

"""Lister of the OS packages installed on the node, from the rpm or dpkg database."""

import logging
import shutil
from dataclasses import dataclass
from typing import List, Optional

from pcluster_diag.core.constants import OS_PACKAGES_COMMAND_TIMEOUT_SECONDS
from pcluster_diag.util.shell import run_command

logger = logging.getLogger(__name__)

_RPM_COMMAND = ["rpm", "-qa", "--queryformat", r"%{NAME}\t%{VERSION}-%{RELEASE}\t%{ARCH}\n"]
# dpkg also lists packages that were removed but kept their configuration files; the status abbreviation
# ``ii`` marks the installed ones.
_DPKG_COMMAND = [
    "dpkg-query",
    "--show",
    "--showformat",
    r"${db:Status-Abbrev}\t${Package}\t${Version}\t${Architecture}\n",
]
_DPKG_INSTALLED_STATUS = "ii"


@dataclass
class OsPackage:
    """An installed OS package."""

    name: str
    version: str
    architecture: str


@dataclass
class OsPackages:
    """The OS packages installed on the node, and the package manager that reported them (rpm or dpkg)."""

    manager: str
    packages: List[OsPackage]


def installed_packages() -> Optional[OsPackages]:
    """Return the installed OS packages sorted by name, or None if neither dpkg-query nor rpm is available.

    dpkg is tried first because Ubuntu can carry an rpm binary, while the RPM-based OSes have no dpkg.

    Raises:
        RuntimeError: If the package manager fails to list the packages.
    """
    if shutil.which("dpkg-query"):
        return OsPackages("dpkg", parse_dpkg_packages(_list(_DPKG_COMMAND)))
    if shutil.which("rpm"):
        return OsPackages("rpm", parse_rpm_packages(_list(_RPM_COMMAND)))
    return None


def _list(command: List[str]) -> str:
    """Run the package manager ``command`` and return its output."""
    result = run_command(command, timeout=OS_PACKAGES_COMMAND_TIMEOUT_SECONDS)
    if result.returncode != 0:
        raise RuntimeError(
            "{} failed with exit code {}: {}".format(command[0], result.returncode, result.stderr.strip())
        )
    return result.stdout


def parse_rpm_packages(output: str) -> List[OsPackage]:
    """Parse the ``name<TAB>version<TAB>arch`` lines printed by ``rpm -qa``."""
    packages = []
    for line in output.splitlines():
        fields = line.split("\t")
        if len(fields) == 3:
            packages.append(OsPackage(*fields))
        elif line.strip():
            logger.warning("Ignoring unparseable rpm output line %r", line)
    return sorted(packages, key=lambda package: (package.name, package.version, package.architecture))


def parse_dpkg_packages(output: str) -> List[OsPackage]:
    """Parse the ``status<TAB>name<TAB>version<TAB>arch`` lines printed by ``dpkg-query``, keeping installed ones."""
    packages = []
    for line in output.splitlines():
        fields = line.split("\t")
        if len(fields) == 4:
            if fields[0].strip() == _DPKG_INSTALLED_STATUS:
                packages.append(OsPackage(*fields[1:]))
        elif line.strip():
            logger.warning("Ignoring unparseable dpkg-query output line %r", line)
    return sorted(packages, key=lambda package: (package.name, package.version, package.architecture))
