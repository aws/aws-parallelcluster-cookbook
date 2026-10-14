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

"""Unit tests for the network congestion check (cumulative ENA allowance counters)."""

import pytest

from pcluster_diag.checks import network_congestion as check_module
from pcluster_diag.checks.network_congestion import NetworkCongestion
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from tests.sample_data import sample_context

_QUIET_ENA = {
    "bw_in_allowance_exceeded": 0,
    "bw_out_allowance_exceeded": 0,
    "pps_allowance_exceeded": 0,
    "conntrack_allowance_exceeded": 0,
    "linklocal_allowance_exceeded": 0,
}


def _codes(findings):
    """Return the set of finding codes (e.g. {'W1', 'I1'}) from a findings list (None-safe)."""
    return {finding.code for finding in (findings or [])}


def _counters(monkeypatch, counters):
    """Make the ENA counter reader return ``counters``."""
    monkeypatch.setattr(check_module.network_counters, "ena_allowance_counters", lambda interface: counters)


@pytest.fixture
def quiet_node(monkeypatch):
    """Patch the primary interface and ENA counters so no allowance was ever exceeded."""
    monkeypatch.setattr(check_module.network_counters, "primary_interface", lambda: "eth0")
    _counters(monkeypatch, dict(_QUIET_ENA))


def test_description():
    assert "network-throttled" in NetworkCongestion().description


def test_runs_on_every_node_type_without_approval():
    for node_type in NodeType:
        context = sample_context(node_type)
        assert NetworkCongestion().should_run(context) is True
        assert NetworkCongestion().approval_required(context) is False


def test_quiet_node_passes(quiet_node):
    result = NetworkCongestion().run(sample_context())

    assert result.status == Status.PASSED
    assert _codes(result.infos) == {"I1"}
    assert "No ENA allowance was exceeded on eth0" in result.infos[0].message


@pytest.mark.parametrize(
    "counter, expected_code",
    [
        ("bw_in_allowance_exceeded", "W1"),
        ("bw_out_allowance_exceeded", "W1"),
        ("pps_allowance_exceeded", "W2"),
        ("conntrack_allowance_exceeded", "W3"),
        ("linklocal_allowance_exceeded", "W4"),
    ],
)
def test_exceeded_allowance_is_a_warning(quiet_node, monkeypatch, counter, expected_code):
    _counters(monkeypatch, dict(_QUIET_ENA, **{counter: 42}))

    result = NetworkCongestion().run(sample_context())

    assert result.status == Status.WARNING
    assert _codes(result.warnings) == {expected_code}
    assert " is 42: since the last device reset" in result.warnings[0].message
    assert "does not record when" in result.warnings[0].message
    assert result.infos is None


@pytest.mark.parametrize(
    "counter, direction", [("bw_in_allowance_exceeded", "inbound"), ("bw_out_allowance_exceeded", "outbound")]
)
def test_bandwidth_warning_names_the_direction(quiet_node, monkeypatch, counter, direction):
    _counters(monkeypatch, dict(_QUIET_ENA, **{counter: 1}))

    result = NetworkCongestion().run(sample_context())

    assert "{} bandwidth allowance".format(direction) in result.warnings[0].message


def test_every_exceeded_allowance_is_reported(quiet_node, monkeypatch):
    _counters(monkeypatch, dict(_QUIET_ENA, pps_allowance_exceeded=5, linklocal_allowance_exceeded=7))

    result = NetworkCongestion().run(sample_context())

    assert result.status == Status.WARNING
    assert _codes(result.warnings) == {"W2", "W4"}


def test_driver_without_allowance_counters_is_a_check_error(quiet_node, monkeypatch):
    _counters(monkeypatch, {})

    result = NetworkCongestion().run(sample_context())

    assert result.status == Status.CHECK_ERROR
    assert result.errors[0].message == (
        "Could not read the ENA allowance counters: the network driver of eth0 does not report them. "
        "Network throttling was not evaluated."
    )


def test_ethtool_failure_is_a_check_error(quiet_node, monkeypatch):
    _counters(monkeypatch, None)

    result = NetworkCongestion().run(sample_context())

    assert result.status == Status.CHECK_ERROR
    assert _codes(result.errors) == {"E0"}
    assert "ethtool -S eth0 failed" in result.errors[0].message


def test_missing_primary_interface_is_a_check_error(quiet_node, monkeypatch):
    monkeypatch.setattr(check_module.network_counters, "primary_interface", lambda: None)

    result = NetworkCongestion().run(sample_context())

    assert result.status == Status.CHECK_ERROR
    assert "primary network interface could not be determined" in result.errors[0].message
