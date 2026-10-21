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

"""Checks reporting the OS packages, and the versions of the critical third-party software, installed on the node.

The critical software is the one ParallelCluster installs: Slurm, EFA, the NVIDIA driver, CUDA, GDRCopy and, on
NVSwitch instances, NVIDIA Fabric Manager. The expected versions are read from the node attributes the cookbook dumps
to /etc/chef/node_attributes.json: at the end of the AMI build, and again when the node is configured (by the gdrcopy
resource). They are the versions of the cookbook, which is the one of the AMI, since a cluster can only use the
ParallelCluster version of its AMI. They are not hardcoded in the tool, so they stay right when the tool is updated
independently of the AMI.

A version that differs from the expected one is a warning, not a failure: the cookbook does not reinstall
software that is already on the base image (e.g. EFA or the NVIDIA stack on a Deep Learning AMI), so a
different version is legitimate there, but it was not tested with this ParallelCluster version. The node
attributes do not keep the versions the cookbook detected on such images, so the warning also shows there.

The kernel modules ParallelCluster installs (EFA, NVIDIA driver, GDRCopy) are built for the kernel of the AMI. When
one is missing for the running kernel but installed for another one, the kernel was changed after the AMI was
built (e.g. by an OS update in a custom action), and the modules do not load.
"""

import dataclasses
from typing import Callable, List, NamedTuple, Optional, Tuple

from pcluster_diag.core.constants import (
    DEFAULT_SLURM_INSTALL_DIR,
    EFA_DRIVER_KERNEL_MODULE,
    GDRCOPY_KERNEL_MODULE,
    NODE_ATTRIBUTES_PATH,
    NVIDIA_DRIVER_KERNEL_MODULE,
)
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context
from pcluster_diag.models.finding import CheckError, CheckFinding, CheckInfo, CheckWarning
from pcluster_diag.models.result import INTERNAL_ERROR_CODE, Result
from pcluster_diag.util import kernel_module, os_packages, software_versions
from pcluster_diag.util.node_attributes import attribute, load_node_attributes

# The values the cookbook accepts as "enabled" for its yes/no attributes (see nvidia_enabled? in the cookbook).
_ENABLED_VALUES = ("yes", True, "true")
_NVIDIA_DRIVER = "NVIDIA driver"
_FABRIC_MANAGER = "NVIDIA Fabric Manager"
_KERNEL = "Kernel"
# Status of a component in the details of CriticalSoftwareVersions.
_EXPECTED_VERSION = "EXPECTED_VERSION"
_DIFFERENT_VERSION = "DIFFERENT_VERSION"
_NOT_INSTALLED = "NOT_INSTALLED"
_NOT_CHECKED = "NOT_CHECKED"


def _software_details(
    name: str, installed: Optional[str] = None, expected: Optional[str] = None, status: Optional[str] = None
) -> dict:
    """Return the details of a software component: its name, installed and expected versions, and status."""
    details = {"name": name, "installed_version": installed, "expected_version": expected, "status": status}
    return {key: value for key, value in details.items() if value is not None}


class InstalledOsPackages(Check):
    """Report the OS packages installed on the node, with their versions."""

    NO_PACKAGE_MANAGER = CheckError(
        INTERNAL_ERROR_CODE, "Neither dpkg-query nor rpm is available: the OS packages were not listed."
    )

    PACKAGES = CheckInfo(1, "{} OS packages are installed (from {}).")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Report the OS packages installed on the node, with their versions."

    def run(self, context: Context) -> Result:
        """List the installed packages; the list goes to the details of the Result.

        A package manager that fails raises, and the Runner records a CHECK_ERROR.
        """
        packages = os_packages.installed_packages()
        if packages is None:
            return Result.from_findings(self, errors=[self.NO_PACKAGE_MANAGER])
        return Result.from_findings(
            self,
            infos=[self.PACKAGES.format(len(packages.packages), packages.manager)],
            details=[dataclasses.asdict(package) for package in packages.packages],
        )


class _Component(NamedTuple):
    """A critical software component, compared on the first ``compared_parts`` components of its version.

    ``installed_version`` is the probe returning its installed version, given the expected one. ``kernel_module`` is
    the kernel module the component installs, if any.
    """

    name: str
    attribute_path: Tuple[str, ...]
    compared_parts: int
    installed_version: Callable[[str], Optional[str]]
    kernel_module: Optional[str] = None


class CriticalSoftwareVersions(Check):
    """Verify that the critical third-party software is installed with the version ParallelCluster installed."""

    NOT_INSTALLED = CheckError(
        1,
        "{} is not installed, or its version cannot be read, but the AMI was built with version {}.",
    )

    FABRIC_MANAGER_NOT_INSTALLED = CheckError(
        2,
        "NVIDIA Fabric Manager is not installed, or its version cannot be read: on NVSwitch instances, the GPUs "
        "cannot be used without it.",
    )
    FABRIC_MANAGER_MISMATCH = CheckError(
        3,
        "NVIDIA Fabric Manager {} does not match the NVIDIA driver {}: on NVSwitch instances they must have the same "
        "version, otherwise the GPUs cannot be used.",
    )

    VERSION_MISMATCH = CheckWarning(
        1,
        "{} {} is installed, but ParallelCluster installed version {} when the AMI was built. The software was "
        "either on the base image already, or changed after the build; this version was not tested with this "
        "ParallelCluster version.",
    )
    KERNEL_CHANGED = CheckWarning(
        2,
        "The {} kernel module is not available for the running kernel {}, but it is installed for kernel {}: the "
        "kernel was likely changed after the AMI was built, and the kernel modules ParallelCluster installed for "
        "the kernel of the AMI do not load.",
    )

    ATTRIBUTES_UNAVAILABLE = CheckError(
        INTERNAL_ERROR_CODE,
        "Could not read the node attributes {}: {}. The installed versions were not compared with the expected ones.",
    )

    NOT_CHECKED = CheckInfo(1, "{} is not checked: {}.")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that Slurm, EFA and the NVIDIA software are installed with the expected versions and kernel."

    def run(self, context: Context) -> Result:
        """Compare the installed version of every applicable component with the one in the node attributes.

        Only the components that are missing or differ are reported, plus the ones that could not be checked. The
        installed and expected version of every checked component, and the running kernel, go to the details of the
        Result.
        """
        try:
            attributes = load_node_attributes()
        except (OSError, ValueError) as error:
            return Result.from_findings(self, errors=[self.ATTRIBUTES_UNAVAILABLE.format(NODE_ATTRIBUTES_PATH, error)])

        errors: List[CheckFinding] = []
        warnings: List[CheckFinding] = []
        infos: List[CheckFinding] = []
        running_kernel = kernel_module.kernel_release()
        details: List[dict] = [_software_details(_KERNEL, running_kernel)]
        components = self._components(context, attributes, infos)
        for component in components:
            expected = attribute(attributes, *component.attribute_path)
            if not expected:
                infos.append(self.NOT_CHECKED.format(component.name, "the node attributes do not record its version"))
                details.append(_software_details(component.name, status=_NOT_CHECKED))
                continue
            expected = str(expected)
            installed = component.installed_version(expected)
            if installed is None:
                errors.append(self.NOT_INSTALLED.format(component.name, expected))
                status = _NOT_INSTALLED
            elif not software_versions.versions_match(installed, expected, component.compared_parts):
                warnings.append(self.VERSION_MISMATCH.format(component.name, installed, expected))
                status = _DIFFERENT_VERSION
            else:
                status = _EXPECTED_VERSION
            details.append(_software_details(component.name, installed, expected, status))

        warnings += self._kernel_changes(components, running_kernel)
        if any(component.name == _NVIDIA_DRIVER for component in components):
            errors += self._fabric_manager_errors(details)
        return Result.from_findings(self, errors=errors, warnings=warnings, infos=infos, details=details)

    def _kernel_changes(self, components: List[_Component], running_kernel: Optional[str]) -> List[CheckFinding]:
        """Return a warning for each kernel module of the components that only exists for another kernel."""
        warnings: List[CheckFinding] = []
        for module in [component.kernel_module for component in components if component.kernel_module]:
            if kernel_module.kernel_module_available(module):
                continue
            other_kernels = [
                kernel for kernel in software_versions.kernels_with_module(module) if kernel != running_kernel
            ]
            if other_kernels:
                warnings.append(self.KERNEL_CHANGED.format(module, running_kernel, ", ".join(other_kernels)))
        return warnings

    def _fabric_manager_errors(self, details: List[dict]) -> List[CheckFinding]:
        """Return the errors of NVIDIA Fabric Manager, on the NVSwitch instances where the cookbook runs it.

        Its versions are added to ``details``: Fabric Manager is expected to have the version of the NVIDIA driver.
        """
        if not software_versions.fabric_manager_expected():
            return []
        fabric_manager = software_versions.fabric_manager_version()
        driver = software_versions.nvidia_driver_version()
        errors: List[CheckFinding] = []
        if fabric_manager is None:
            errors.append(self.FABRIC_MANAGER_NOT_INSTALLED)
            status = _NOT_INSTALLED
        elif driver and not software_versions.versions_match(fabric_manager, driver, 3):
            errors.append(self.FABRIC_MANAGER_MISMATCH.format(fabric_manager, driver))
            status = _DIFFERENT_VERSION
        else:
            status = _EXPECTED_VERSION
        details.append(_software_details(_FABRIC_MANAGER, fabric_manager, driver, status))
        return errors

    def _components(self, context: Context, attributes: dict, infos: List[CheckFinding]) -> List[_Component]:
        """Return the components that apply to this node, adding to ``infos`` why the NVIDIA ones do not."""
        install_dir = (((context.dna_json or {}).get("cluster") or {}).get("slurm") or {}).get(
            "install_dir"
        ) or DEFAULT_SLURM_INSTALL_DIR
        components = [
            _Component(
                "Slurm", ("cluster", "slurm", "version"), 3, lambda _: software_versions.slurm_version(install_dir)
            ),
            _Component(
                "EFA",
                ("cluster", "efa", "version"),
                3,
                lambda _: software_versions.efa_installer_version(),
                EFA_DRIVER_KERNEL_MODULE,
            ),
        ]

        if attribute(attributes, "cluster", "nvidia", "enabled") not in _ENABLED_VALUES:
            infos.append(self.NOT_CHECKED.format("The NVIDIA software", "the AMI was built with NVIDIA disabled"))
            return components
        if not software_versions.has_nvidia_gpu():
            infos.append(self.NOT_CHECKED.format("The NVIDIA software", "the instance has no NVIDIA GPU"))
            return components

        components += [
            _Component(
                _NVIDIA_DRIVER,
                ("cluster", "nvidia", "driver_version"),
                3,
                lambda _: software_versions.nvidia_driver_version(),
                NVIDIA_DRIVER_KERNEL_MODULE,
            ),
            _Component("CUDA", ("cluster", "nvidia", "cuda", "version"), 2, software_versions.cuda_version),
        ]
        if attribute(attributes, "cluster", "nvidia", "gdrcopy", "enabled") in _ENABLED_VALUES:
            components.append(
                _Component(
                    "NVIDIA GDRCopy",
                    ("cluster", "nvidia", "gdrcopy", "version"),
                    2,
                    lambda _: software_versions.gdrcopy_version(),
                    GDRCOPY_KERNEL_MODULE,
                )
            )
        else:
            infos.append(self.NOT_CHECKED.format("NVIDIA GDRCopy", "the AMI was built with GDRCopy disabled"))
        return components
