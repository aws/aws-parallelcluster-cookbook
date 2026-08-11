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

"""Unit tests for the critical-paths permission check."""

import pytest

from pcluster_diag.checks import critical_paths
from pcluster_diag.checks.critical_paths import CriticalPathsHaveExpectedPermissions
from pcluster_diag.core.constants import (
    COMPUTEFLEET_STATUS_PATH,
    GROUP_OTHER_READ_WRITE,
    GROUP_OTHER_WRITE,
    MUNGE_KEY_PATH,
    OWNER_READ,
    OWNER_TRAVERSE,
    OWNER_WRITE,
    SLURM_STATE_SAVE_PATH,
)
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.expected_path_permissions import ExpectedPathPermissions
from pcluster_diag.models.result import Status
from pcluster_diag.util.path_permissions import PathStat
from tests.sample_data import sample_context

# A single head-node critical path used by most tests (mirrors computefleet-status.json).
_HEAD_PATH = ExpectedPathPermissions(
    path="/opt/parallelcluster/shared/computefleet-status.json",
    owner="pcluster-admin",
    group="pcluster-admin",
    node_types=(NodeType.HEAD,),
    required_bits=OWNER_WRITE,
    forbidden_bits=GROUP_OTHER_WRITE,
)


def _check(paths=None):
    """Build the check with an explicit path list (defaults to the single head-node path)."""
    return CriticalPathsHaveExpectedPermissions(critical_paths=[_HEAD_PATH] if paths is None else paths)


def _fake_stat(monkeypatch, mapping):
    """Patch path_permissions.stat_path: mapping is path -> PathStat, a missing key raises FileNotFoundError."""

    def stat_path(path):
        if path not in mapping:
            raise FileNotFoundError(path)
        return mapping[path]

    monkeypatch.setattr(critical_paths.path_permissions, "stat_path", stat_path)


def _codes(result):
    """Return the list of error codes carried by a Result (empty list when it has no errors)."""
    return [error.code for error in (result.errors or [])]


def _messages(result):
    """Return the joined error messages carried by a Result."""
    return " | ".join(error.message for error in (result.errors or []))


@pytest.mark.parametrize(
    "path, owner, group, required_bits, forbidden_bits, node_types",
    [
        (
            COMPUTEFLEET_STATUS_PATH,
            "pcluster-admin",
            "pcluster-admin",
            OWNER_WRITE,
            GROUP_OTHER_WRITE,
            (NodeType.HEAD,),
        ),
        (
            MUNGE_KEY_PATH,
            "munge",
            "munge",
            OWNER_READ,
            GROUP_OTHER_READ_WRITE,
            (NodeType.HEAD, NodeType.COMPUTE, NodeType.LOGIN),
        ),
        (
            SLURM_STATE_SAVE_PATH,
            "slurm",
            "slurm",
            OWNER_READ | OWNER_WRITE | OWNER_TRAVERSE,
            GROUP_OTHER_WRITE,
            (NodeType.HEAD,),
        ),
    ],
)
def test_default_critical_paths_are_registered(path, owner, group, required_bits, forbidden_bits, node_types):
    entry = next(c for c in critical_paths.CRITICAL_PATHS if c.path == path)

    assert (entry.owner, entry.group, entry.node_types) == (owner, group, node_types)
    assert (entry.required_bits, entry.forbidden_bits) == (required_bits, forbidden_bits)
    assert entry.required_bits & entry.forbidden_bits == 0
    assert entry.allowed_modes is None, "critical paths express themselves in bits, not exact modes"


@pytest.mark.parametrize(
    "path, mode",
    [
        # 0755 is the mode Slurm itself uses when it creates the StateSaveLocation (mkdir(path, 0755)).
        (SLURM_STATE_SAVE_PATH, "0755"),
        (SLURM_STATE_SAVE_PATH, "0700"),
        (MUNGE_KEY_PATH, "0400"),
        (MUNGE_KEY_PATH, "0600"),
        (COMPUTEFLEET_STATUS_PATH, "0600"),
        (COMPUTEFLEET_STATUS_PATH, "0755"),
    ],
)
def test_default_critical_paths_accept_every_mode_their_daemon_tolerates(monkeypatch, path, mode):
    entry = next(c for c in critical_paths.CRITICAL_PATHS if c.path == path)
    _fake_stat(monkeypatch, {path: PathStat(owner=entry.owner, group=entry.group, mode=mode)})

    result = CriticalPathsHaveExpectedPermissions(critical_paths=[entry]).run(sample_context(NodeType.HEAD))

    assert result.status is Status.PASSED, "mode {} should be tolerated for {}".format(mode, path)


@pytest.mark.parametrize(
    "path, mode, expected_code",
    [
        # 0600 strips the traverse bit slurmctld needs: tightening is as fatal as loosening here.
        (SLURM_STATE_SAVE_PATH, "0600", CriticalPathsHaveExpectedPermissions.MISSING_PERMISSIONS.code),
        # munged runs unprivileged, so a key it cannot read stops it from starting.
        (MUNGE_KEY_PATH, "0000", CriticalPathsHaveExpectedPermissions.MISSING_PERMISSIONS.code),
        (MUNGE_KEY_PATH, "0640", CriticalPathsHaveExpectedPermissions.INSECURE_PERMISSIONS.code),
        (MUNGE_KEY_PATH, "0604", CriticalPathsHaveExpectedPermissions.INSECURE_PERMISSIONS.code),
        (COMPUTEFLEET_STATUS_PATH, "0455", CriticalPathsHaveExpectedPermissions.MISSING_PERMISSIONS.code),
    ],
)
def test_default_critical_paths_reject_modes_that_break_their_daemon(monkeypatch, path, mode, expected_code):
    entry = next(c for c in critical_paths.CRITICAL_PATHS if c.path == path)
    _fake_stat(monkeypatch, {path: PathStat(owner=entry.owner, group=entry.group, mode=mode)})

    result = CriticalPathsHaveExpectedPermissions(critical_paths=[entry]).run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [expected_code]


@pytest.mark.parametrize(
    "path, mode, granted",
    [
        # slurmctld starts fine on a world-writable StateSaveLocation, and clusterstatusmgtd only needs
        # owner write, so these expose the path without breaking the cluster.
        (SLURM_STATE_SAVE_PATH, "0777", "group write, other write"),
        (COMPUTEFLEET_STATUS_PATH, "0757", "other write"),
    ],
)
def test_over_permissive_mode_is_a_warning_when_the_daemon_keeps_running(monkeypatch, path, mode, granted):
    entry = next(c for c in critical_paths.CRITICAL_PATHS if c.path == path)
    _fake_stat(monkeypatch, {path: PathStat(owner=entry.owner, group=entry.group, mode=mode)})

    result = CriticalPathsHaveExpectedPermissions(critical_paths=[entry]).run(sample_context(NodeType.HEAD))

    assert result.status is Status.WARNING
    assert result.errors is None
    assert _codes(result) == []
    assert [w.code for w in result.warnings] == [CriticalPathsHaveExpectedPermissions.OVER_PERMISSIVE.code]
    assert "should not grant {}".format(granted) in result.warnings[0].message


def test_over_permissive_mode_is_a_failure_when_it_stops_the_daemon(monkeypatch):
    # munged refuses to start from a key others can read, so here it is not merely an advisory.
    entry = next(c for c in critical_paths.CRITICAL_PATHS if c.path == MUNGE_KEY_PATH)
    _fake_stat(monkeypatch, {MUNGE_KEY_PATH: PathStat(owner="munge", group="munge", mode="0640")})

    result = CriticalPathsHaveExpectedPermissions(critical_paths=[entry]).run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [CriticalPathsHaveExpectedPermissions.INSECURE_PERMISSIONS.code]


def test_munge_key_is_inspected_on_every_node_type_that_runs_munged():
    entry = next(c for c in critical_paths.CRITICAL_PATHS if c.path == MUNGE_KEY_PATH)

    # The cookbook installs the key identically on head, compute and login nodes (setup_munge_key).
    assert set(entry.node_types) == set(NodeType)


def test_description():
    assert "critical files" in _check().description


@pytest.mark.parametrize("node_type", list(NodeType), ids=lambda nt: nt.name)
def test_always_runs(node_type):
    # The check always applies; a node type with no applicable path simply passes (below).
    assert _check().should_run(sample_context(node_type)) is True


def test_run_passes_when_no_path_applies_to_node_type(monkeypatch):
    # The sample path is HEAD-only, so on a compute node there is nothing to inspect -> PASSED.
    inspected = []
    monkeypatch.setattr(
        critical_paths.path_permissions,
        "stat_path",
        lambda path: inspected.append(path) or PathStat(owner="x", group="x", mode="0000"),
    )

    result = _check().run(sample_context(NodeType.COMPUTE))

    assert result.status is Status.PASSED
    assert inspected == []


def test_run_passes_when_ownership_and_permissions_are_satisfied(monkeypatch):
    _fake_stat(monkeypatch, {_HEAD_PATH.path: PathStat(owner="pcluster-admin", group="pcluster-admin", mode="0755")})

    result = _check().run(sample_context(NodeType.HEAD))

    assert result.status is Status.PASSED
    assert result.errors is None


def test_run_fails_when_owner_wrong(monkeypatch):
    # The file exists but is no longer owned by pcluster-admin.
    _fake_stat(monkeypatch, {_HEAD_PATH.path: PathStat(owner="root", group="pcluster-admin", mode="0755")})

    result = _check().run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [CriticalPathsHaveExpectedPermissions.WRONG_OWNERSHIP.code]
    assert "is owned by root:pcluster-admin but should be pcluster-admin:pcluster-admin" in _messages(result)


def test_run_fails_when_group_wrong(monkeypatch):
    _fake_stat(monkeypatch, {_HEAD_PATH.path: PathStat(owner="pcluster-admin", group="root", mode="0755")})

    result = _check().run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [CriticalPathsHaveExpectedPermissions.WRONG_OWNERSHIP.code]
    assert "pcluster-admin:root but should be pcluster-admin:pcluster-admin" in _messages(result)


def test_run_fails_when_required_permission_missing(monkeypatch):
    _fake_stat(monkeypatch, {_HEAD_PATH.path: PathStat(owner="pcluster-admin", group="pcluster-admin", mode="0555")})

    result = _check().run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [CriticalPathsHaveExpectedPermissions.MISSING_PERMISSIONS.code]
    assert "has mode 0555, which does not grant owner write" in _messages(result)


def test_findings_state_the_observation_without_explaining_consequences(monkeypatch):
    # Findings describe the observation against the expectation; the impact belongs to the status.
    _fake_stat(monkeypatch, {_HEAD_PATH.path: PathStat(owner="pcluster-admin", group="pcluster-admin", mode="0555")})

    message = _messages(_check().run(sample_context(NodeType.HEAD)))

    assert message == "'{}' has mode 0555, which does not grant owner write.".format(_HEAD_PATH.path)


def test_run_warns_when_forbidden_permission_granted(monkeypatch):
    _fake_stat(monkeypatch, {_HEAD_PATH.path: PathStat(owner="pcluster-admin", group="pcluster-admin", mode="0757")})

    result = _check().run(sample_context(NodeType.HEAD))

    assert result.status is Status.WARNING
    assert "which should not grant other write" in result.warnings[0].message


def test_run_passes_when_mode_is_stricter_than_the_cookbook_default(monkeypatch):
    # Tightening 0755 -> 0600 keeps owner write, so it must not be reported as a failure.
    _fake_stat(monkeypatch, {_HEAD_PATH.path: PathStat(owner="pcluster-admin", group="pcluster-admin", mode="0600")})

    result = _check().run(sample_context(NodeType.HEAD))

    assert result.status is Status.PASSED


def test_run_reports_both_missing_and_over_permissive_findings(monkeypatch):
    # 0557 has no owner write (required) and is group/other writable (advisory).
    _fake_stat(monkeypatch, {_HEAD_PATH.path: PathStat(owner="pcluster-admin", group="pcluster-admin", mode="0557")})

    result = _check().run(sample_context(NodeType.HEAD))

    # A failure outranks a warning, so the check still fails overall.
    assert result.status is Status.FAILURE
    assert _codes(result) == [CriticalPathsHaveExpectedPermissions.MISSING_PERMISSIONS.code]
    assert [w.code for w in result.warnings] == [CriticalPathsHaveExpectedPermissions.OVER_PERMISSIVE.code]


def test_run_reports_both_ownership_and_permissions_when_both_wrong(monkeypatch):
    _fake_stat(monkeypatch, {_HEAD_PATH.path: PathStat(owner="root", group="root", mode="0555")})

    result = _check().run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [
        CriticalPathsHaveExpectedPermissions.WRONG_OWNERSHIP.code,
        CriticalPathsHaveExpectedPermissions.MISSING_PERMISSIONS.code,
    ]


def test_run_fails_when_path_missing(monkeypatch):
    _fake_stat(monkeypatch, {})  # nothing exists -> FileNotFoundError

    result = _check().run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [CriticalPathsHaveExpectedPermissions.MISSING_PATH.code]
    assert "is missing" in _messages(result)


def test_run_only_inspects_paths_for_current_node_type(monkeypatch):
    compute_path = ExpectedPathPermissions("/x", "root", "root", (NodeType.COMPUTE,), required_bits=OWNER_READ)
    inspected = []

    def stat_path(path):
        inspected.append(path)
        return PathStat(owner="pcluster-admin", group="pcluster-admin", mode="0755")

    monkeypatch.setattr(critical_paths.path_permissions, "stat_path", stat_path)

    _check([_HEAD_PATH, compute_path]).run(sample_context(NodeType.HEAD))

    # Only the HEAD path is inspected; the compute-only path is skipped on the head node.
    assert inspected == [_HEAD_PATH.path]
