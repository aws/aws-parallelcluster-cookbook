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

"""Unit tests for the critical system services check."""

import pytest

from pcluster_diag.checks import critical_services
from pcluster_diag.checks.critical_services import CriticalServicesAreRunning
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from tests.sample_data import sample_context
from tests.stubs import stub_returning


def _patch(
    monkeypatch,
    states=None,
    ports=frozenset({2049, 6818, 6820}),
    gpu=False,
    gdrcopy_installed=True,
    fabric_manager_expected=False,
):
    """Patch the unit states (``active`` unless overridden), listening ports, GPU, GDRCopy and Fabric Manager."""
    queried = []

    def fake_state(unit):
        queried.append(unit)
        return (states or {}).get(unit, "active")

    monkeypatch.setattr(critical_services.services, "systemd_unit_state", fake_state)
    monkeypatch.setattr(critical_services.services, "systemd_unit_exists", stub_returning(gdrcopy_installed))
    monkeypatch.setattr(critical_services.software_versions, "has_nvidia_gpu", stub_returning(gpu))
    monkeypatch.setattr(
        critical_services.software_versions, "fabric_manager_expected", stub_returning(fabric_manager_expected)
    )
    monkeypatch.setattr(
        critical_services.listening_ports, "listening_tcp_ports", stub_returning(None if ports is None else set(ports))
    )
    return queried


@pytest.mark.parametrize(
    "node_type, base_os, expected_units",
    [
        (NodeType.HEAD, "alinux2023", ["munge.service", "slurmctld.service", "nfs-server.service"]),
        (NodeType.HEAD, "ubuntu2404", ["munge.service", "slurmctld.service", "nfs-kernel-server.service"]),
        (NodeType.COMPUTE, "rhel9", ["munge.service", "slurmd.service"]),
        (NodeType.LOGIN, "rhel9", ["munge.service"]),
    ],
)
def test_services_all_healthy_passes(monkeypatch, node_type, base_os, expected_units):
    queried = _patch(monkeypatch)

    result = CriticalServicesAreRunning().run(sample_context(node_type, base_os=base_os))

    assert result.status is Status.PASSED
    assert queried == expected_units
    assert result.errors is None


def test_services_healthy_reports_nothing(monkeypatch):
    _patch(monkeypatch)

    result = CriticalServicesAreRunning().run(sample_context(NodeType.HEAD, base_os="alinux2023"))

    # Only the services that are not active, or not listening, are reported.
    assert (result.errors, result.warnings, result.infos) == (None, None, None)


def test_services_inactive_service_fails(monkeypatch):
    _patch(monkeypatch, states={"nfs-server.service": "failed", "munge.service": None})

    result = CriticalServicesAreRunning().run(sample_context(NodeType.HEAD, base_os="alinux2023"))

    assert result.status is Status.FAILURE
    assert [error.message for error in result.errors] == [
        "munge.service is in an unknown state, expected active.",
        "nfs-server.service is failed, expected active.",
    ]


def test_services_port_not_listening_fails(monkeypatch):
    _patch(monkeypatch, ports={2049})

    result = CriticalServicesAreRunning().run(sample_context(NodeType.HEAD, base_os="alinux2023"))

    assert result.status is Status.FAILURE
    assert [(error.code, error.message) for error in result.errors] == [
        ("E2", "slurmctld.service is active, but no process listens on TCP ports 6820-6829.")
    ]


def test_services_unreadable_ports_is_a_check_error(monkeypatch):
    _patch(monkeypatch, ports=None)

    result = CriticalServicesAreRunning().run(sample_context(NodeType.COMPUTE))

    assert result.status is Status.CHECK_ERROR
    assert [error.code for error in result.errors] == ["E0"]
    assert result.infos is None


def test_services_ports_not_read_when_no_service_has_ports(monkeypatch):
    _patch(monkeypatch)
    monkeypatch.setattr(
        critical_services.listening_ports, "listening_tcp_ports", lambda: pytest.fail("ports must not be read")
    )

    result = CriticalServicesAreRunning().run(sample_context(NodeType.LOGIN))

    assert result.status is Status.PASSED


@pytest.mark.parametrize(
    "base_os, gpu, installed, expected_gdrcopy",
    [
        ("alinux2023", True, True, "gdrcopy.service"),
        ("ubuntu2204", True, True, "gdrdrv.service"),
        ("alinux2023", False, True, None),
        ("alinux2023", True, False, None),
    ],
)
def test_services_gdrcopy_only_on_gpu_instances_with_it_installed(
    monkeypatch, base_os, gpu, installed, expected_gdrcopy
):
    queried = _patch(monkeypatch, gpu=gpu, gdrcopy_installed=installed)

    CriticalServicesAreRunning().run(sample_context(NodeType.COMPUTE, base_os=base_os))

    assert queried[2:] == ([expected_gdrcopy] if expected_gdrcopy else [])


@pytest.mark.parametrize(
    "gpu, fabric_manager_expected, installed, expected_units",
    [
        (True, True, True, ["gdrcopy.service", "nvidia-fabricmanager.service"]),
        (True, False, True, ["gdrcopy.service"]),
        (True, True, False, []),
        (False, True, True, []),
    ],
)
def test_services_fabric_manager_on_nvswitch_instances(
    monkeypatch, gpu, fabric_manager_expected, installed, expected_units
):
    queried = _patch(monkeypatch, gpu=gpu, gdrcopy_installed=installed, fabric_manager_expected=fabric_manager_expected)

    CriticalServicesAreRunning().run(sample_context(NodeType.COMPUTE, base_os="alinux2023"))

    assert queried[2:] == expected_units


def test_services_single_port_not_listening_fails(monkeypatch):
    _patch(monkeypatch, ports={22})

    result = CriticalServicesAreRunning().run(sample_context(NodeType.COMPUTE))

    assert [error.message for error in result.errors] == [
        "slurmd.service is active, but no process listens on TCP port 6818."
    ]
