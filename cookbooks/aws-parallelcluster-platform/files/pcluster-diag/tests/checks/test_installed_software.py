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

"""Unit tests for the installed OS packages and critical software version checks."""

import pytest

from pcluster_diag.checks import installed_software
from pcluster_diag.checks.installed_software import CriticalSoftwareVersions, InstalledOsPackages
from pcluster_diag.models.result import Status
from pcluster_diag.util.os_packages import OsPackage, OsPackages
from tests.sample_data import sample_context
from tests.stubs import stub_raising, stub_returning

_EXPECTED = {
    "cluster": {
        "slurm": {"version": "25-11-8-1"},
        "efa": {"version": "1.49.0"},
        "nvidia": {
            "enabled": "yes",
            "driver_version": "595.71.05",
            "cuda": {"version": "13.2.2"},
            "gdrcopy": {"enabled": True, "version": "2.6"},
        },
    }
}

_INSTALLED = {
    "slurm_version": "25.11.8",
    "efa_installer_version": "1.49.0",
    "nvidia_driver_version": "595.71.05",
    "cuda_version": "13.2",
    "gdrcopy_version": "2.6",
}


# --- InstalledOsPackages ---------------------------------------------------------------


def test_os_packages_reports_count_and_details(monkeypatch):
    packages = OsPackages("rpm", [OsPackage("bash", "5.1.8-9.el9", "x86_64"), OsPackage("zlib", "1.2.11", "x86_64")])
    monkeypatch.setattr(installed_software.os_packages, "installed_packages", stub_returning(packages))

    result = InstalledOsPackages().run(sample_context())

    assert result.status is Status.PASSED
    assert [info.message for info in result.infos] == ["2 OS packages are installed (from rpm)."]
    assert result.details == [
        {"name": "bash", "version": "5.1.8-9.el9", "architecture": "x86_64"},
        {"name": "zlib", "version": "1.2.11", "architecture": "x86_64"},
    ]


def test_os_packages_check_error_without_package_manager(monkeypatch):
    monkeypatch.setattr(installed_software.os_packages, "installed_packages", stub_returning(None))

    result = InstalledOsPackages().run(sample_context())

    assert result.status is Status.CHECK_ERROR
    assert [error.code for error in result.errors] == ["E0"]
    assert result.details is None


# --- CriticalSoftwareVersions ----------------------------------------------------------


def _patch(
    monkeypatch,
    attributes=None,
    installed=None,
    gpu=True,
    modules_for_running_kernel=True,
    kernels=None,
    fabric_manager_expected=False,
    fabric_manager="595.71.05",
):
    """Patch the node attributes, the installed-version, kernel module and Fabric Manager probes, and the GPU."""
    monkeypatch.setattr(installed_software, "load_node_attributes", stub_returning(attributes or _EXPECTED))
    monkeypatch.setattr(
        installed_software.kernel_module, "kernel_module_available", stub_returning(modules_for_running_kernel)
    )
    monkeypatch.setattr(installed_software.kernel_module, "kernel_release", stub_returning("6.1.200-1.amzn2023.x86_64"))
    monkeypatch.setattr(installed_software.software_versions, "kernels_with_module", stub_returning(kernels or []))
    monkeypatch.setattr(
        installed_software.software_versions, "fabric_manager_expected", stub_returning(fabric_manager_expected)
    )
    monkeypatch.setattr(installed_software.software_versions, "fabric_manager_version", stub_returning(fabric_manager))
    probes = dict(_INSTALLED, **(installed or {}))
    calls = {}

    def probe(name):
        def _probe(*args):
            calls[name] = args
            return probes[name]

        return _probe

    for name in probes:
        monkeypatch.setattr(installed_software.software_versions, name, probe(name))
    monkeypatch.setattr(installed_software.software_versions, "has_nvidia_gpu", stub_returning(gpu))
    return calls


def test_versions_all_expected_passes(monkeypatch):
    calls = _patch(monkeypatch)

    result = CriticalSoftwareVersions().run(sample_context())

    # Only the components that are missing, differ or are not checked are reported.
    assert result.status is Status.PASSED
    assert (result.errors, result.warnings, result.infos) == (None, None, None)
    assert set(calls) == {
        "slurm_version",
        "efa_installer_version",
        "nvidia_driver_version",
        "cuda_version",
        "gdrcopy_version",
    }
    assert calls["slurm_version"] == ("/opt/slurm",)
    assert calls["cuda_version"] == ("13.2.2",)


def test_versions_reads_slurm_from_the_configured_install_dir(monkeypatch):
    calls = _patch(monkeypatch)
    context = sample_context()
    context.dna_json["cluster"]["slurm"] = {"install_dir": "/custom/slurm"}

    CriticalSoftwareVersions().run(context)

    assert calls["slurm_version"] == ("/custom/slurm",)


def test_versions_mismatch_is_a_warning(monkeypatch):
    _patch(monkeypatch, installed={"efa_installer_version": "1.47.0", "nvidia_driver_version": "580.82.07"})

    result = CriticalSoftwareVersions().run(sample_context())

    assert result.status is Status.WARNING
    assert [warning.code for warning in result.warnings] == ["W1", "W1"]
    assert result.warnings[0].message.startswith(
        "EFA 1.47.0 is installed, but ParallelCluster installed version 1.49.0 when the AMI was built."
    )
    assert result.warnings[1].message.startswith("NVIDIA driver 580.82.07 is installed")


def test_versions_missing_component_is_a_failure(monkeypatch):
    _patch(monkeypatch, installed={"slurm_version": None, "cuda_version": "13.1"})

    result = CriticalSoftwareVersions().run(sample_context())

    assert result.status is Status.FAILURE
    assert [error.message for error in result.errors] == [
        "Slurm is not installed, or its version cannot be read, but the AMI was built with version 25-11-8-1."
    ]
    assert [warning.message.split(" is installed")[0] for warning in result.warnings] == ["CUDA 13.1"]


def test_versions_skip_nvidia_without_gpu(monkeypatch):
    calls = _patch(monkeypatch, gpu=False)

    result = CriticalSoftwareVersions().run(sample_context())

    assert result.status is Status.PASSED
    assert "The NVIDIA software is not checked: the instance has no NVIDIA GPU." in [i.message for i in result.infos]
    assert set(calls) == {"slurm_version", "efa_installer_version"}


@pytest.mark.parametrize("enabled", ["no", False, None])
def test_versions_skip_nvidia_when_disabled_at_build(monkeypatch, enabled):
    attributes = {"cluster": dict(_EXPECTED["cluster"], nvidia={"enabled": enabled})}
    calls = _patch(monkeypatch, attributes=attributes)

    result = CriticalSoftwareVersions().run(sample_context())

    assert "The NVIDIA software is not checked: the AMI was built with NVIDIA disabled." in [
        info.message for info in result.infos
    ]
    assert set(calls) == {"slurm_version", "efa_installer_version"}


def test_versions_skip_gdrcopy_when_disabled_at_build(monkeypatch):
    nvidia = dict(_EXPECTED["cluster"]["nvidia"], gdrcopy={"enabled": False, "version": "2.6"})
    calls = _patch(monkeypatch, attributes={"cluster": dict(_EXPECTED["cluster"], nvidia=nvidia)})

    result = CriticalSoftwareVersions().run(sample_context())

    assert "NVIDIA GDRCopy is not checked: the AMI was built with GDRCopy disabled." in [
        info.message for info in result.infos
    ]
    assert "gdrcopy_version" not in calls


def test_versions_not_checked_when_attribute_missing(monkeypatch):
    attributes = {"cluster": {"slurm": {"version": "25-11-8-1"}, "nvidia": {"enabled": "no"}}}
    calls = _patch(monkeypatch, attributes=attributes)

    result = CriticalSoftwareVersions().run(sample_context())

    assert result.status is Status.PASSED
    assert "EFA is not checked: the node attributes do not record its version." in [i.message for i in result.infos]
    assert "efa_installer_version" not in calls


@pytest.mark.parametrize("error", [OSError("No such file"), ValueError("not a JSON object")])
def test_versions_check_error_when_attributes_unreadable(monkeypatch, error):
    monkeypatch.setattr(installed_software, "load_node_attributes", stub_raising(error))

    result = CriticalSoftwareVersions().run(sample_context())

    assert result.status is Status.CHECK_ERROR
    assert [finding.code for finding in result.errors] == ["E0"]
    assert result.errors[0].message.startswith("Could not read the node attributes /etc/chef/node_attributes.json")


def test_versions_kernel_changed_is_a_warning(monkeypatch):
    _patch(
        monkeypatch,
        installed={"nvidia_driver_version": None},
        modules_for_running_kernel=False,
        kernels=["6.1.155-176.282.amzn2023.x86_64"],
    )

    result = CriticalSoftwareVersions().run(sample_context())

    assert result.status is Status.FAILURE
    assert [error.message.split(" is not installed")[0] for error in result.errors] == ["NVIDIA driver"]
    # One warning per kernel module of the checked components (efa, nvidia, gdrdrv) missing for the running kernel.
    assert [warning.code for warning in result.warnings] == ["W2", "W2", "W2"]
    assert result.warnings[1].message.startswith(
        "The nvidia kernel module is not available for the running kernel 6.1.200-1.amzn2023.x86_64, but it is "
        "installed for kernel 6.1.155-176.282.amzn2023.x86_64: the kernel was likely changed after the AMI was built"
    )


@pytest.mark.parametrize(
    "modules_for_running_kernel, kernels",
    [
        pytest.param(True, ["6.1.155-176.282.amzn2023.x86_64"], id="module available for the running kernel"),
        pytest.param(False, [], id="module installed for no kernel"),
        pytest.param(False, ["6.1.200-1.amzn2023.x86_64"], id="module only installed for the running kernel"),
    ],
)
def test_versions_no_kernel_warning(monkeypatch, modules_for_running_kernel, kernels):
    _patch(monkeypatch, modules_for_running_kernel=modules_for_running_kernel, kernels=kernels)

    result = CriticalSoftwareVersions().run(sample_context())

    assert result.warnings is None


@pytest.mark.parametrize(
    "fabric_manager, expected_errors",
    [
        pytest.param("595.71.05", None, id="same version as the driver"),
        pytest.param(
            "580.82.07",
            [
                "NVIDIA Fabric Manager 580.82.07 does not match the NVIDIA driver 595.71.05: on NVSwitch instances "
                "they must have the same version, otherwise the GPUs cannot be used."
            ],
            id="different version",
        ),
        pytest.param(
            None,
            [
                "NVIDIA Fabric Manager is not installed, or its version cannot be read: on NVSwitch instances, the "
                "GPUs cannot be used without it."
            ],
            id="not installed",
        ),
    ],
)
def test_versions_fabric_manager_on_nvswitch_instances(monkeypatch, fabric_manager, expected_errors):
    _patch(monkeypatch, fabric_manager_expected=True, fabric_manager=fabric_manager)

    result = CriticalSoftwareVersions().run(sample_context())

    assert (None if result.errors is None else [error.message for error in result.errors]) == expected_errors


@pytest.mark.parametrize("gpu, fabric_manager_expected", [(True, False), (False, True)])
def test_versions_fabric_manager_not_checked(monkeypatch, gpu, fabric_manager_expected):
    _patch(monkeypatch, gpu=gpu, fabric_manager_expected=fabric_manager_expected, fabric_manager=None)

    result = CriticalSoftwareVersions().run(sample_context())

    assert result.errors is None


def test_versions_details_list_every_checked_component(monkeypatch):
    _patch(
        monkeypatch,
        installed={"efa_installer_version": "1.47.0", "gdrcopy_version": None},
        fabric_manager_expected=True,
    )

    result = CriticalSoftwareVersions().run(sample_context())

    assert result.details == [
        {"name": "Kernel", "installed_version": "6.1.200-1.amzn2023.x86_64"},
        {
            "name": "Slurm",
            "installed_version": "25.11.8",
            "expected_version": "25-11-8-1",
            "status": "EXPECTED_VERSION",
        },
        {"name": "EFA", "installed_version": "1.47.0", "expected_version": "1.49.0", "status": "DIFFERENT_VERSION"},
        {
            "name": "NVIDIA driver",
            "installed_version": "595.71.05",
            "expected_version": "595.71.05",
            "status": "EXPECTED_VERSION",
        },
        {"name": "CUDA", "installed_version": "13.2", "expected_version": "13.2.2", "status": "EXPECTED_VERSION"},
        {"name": "NVIDIA GDRCopy", "expected_version": "2.6", "status": "NOT_INSTALLED"},
        {
            "name": "NVIDIA Fabric Manager",
            "installed_version": "595.71.05",
            "expected_version": "595.71.05",
            "status": "EXPECTED_VERSION",
        },
    ]


def test_versions_details_without_nvidia_and_unrecorded_versions(monkeypatch):
    attributes = {"cluster": {"slurm": {"version": "25-11-8-1"}, "nvidia": {"enabled": "no"}}}
    _patch(monkeypatch, attributes=attributes)

    result = CriticalSoftwareVersions().run(sample_context())

    assert result.details == [
        {"name": "Kernel", "installed_version": "6.1.200-1.amzn2023.x86_64"},
        {
            "name": "Slurm",
            "installed_version": "25.11.8",
            "expected_version": "25-11-8-1",
            "status": "EXPECTED_VERSION",
        },
        {"name": "EFA", "status": "NOT_CHECKED"},
    ]
