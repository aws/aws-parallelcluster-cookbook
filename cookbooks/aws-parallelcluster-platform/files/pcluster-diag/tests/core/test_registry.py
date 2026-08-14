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

"""Unit tests for the Registry: registration order, identifier resolution, duplicates, and selection."""

import logging

import pytest

import pcluster_diag.core.registry as registry_module
from pcluster_diag.core.registry import Registry
from tests.sample_data import FakeCheck, sample_context


def test_registered_checks_empty_by_default():
    assert Registry().registered_checks() == []


def test_register_preserves_registration_order():
    registry = Registry()
    a, b, c = FakeCheck("A"), FakeCheck("B"), FakeCheck("C")

    registry.register(a)
    registry.register(b)
    registry.register(c)

    assert registry.registered_checks() == [a, b, c]


@pytest.mark.parametrize(
    "identifier, expected_index",
    [("A", 0), ("B", 1), ("Missing", None)],
    ids=["resolves-first", "resolves-second", "unregistered-returns-none"],
)
def test_get_returns_check_by_identifier_or_none(identifier, expected_index):
    registry = Registry()
    checks = [FakeCheck("A"), FakeCheck("B")]
    for check in checks:
        registry.register(check)

    resolved = registry.get(identifier)

    if expected_index is None:
        # An unregistered identifier resolves to None and never appears among registered checks.
        assert resolved is None
        assert all(check.identifier != identifier for check in registry.registered_checks())
    else:
        assert resolved is checks[expected_index]


@pytest.mark.parametrize(
    "register_later",
    [False, True],
    ids=["keeps-first-and-warns", "does-not-abort-subsequent-registration"],
)
def test_duplicate_identifier_keeps_first_warns_and_does_not_abort(caplog, register_later):
    registry = Registry()
    first = FakeCheck("Dup", description="first")
    second = FakeCheck("Dup", description="second")
    later = FakeCheck("Later")

    registry.register(first)
    with caplog.at_level(logging.WARNING):
        registry.register(second)
    if register_later:
        registry.register(later)

    # The first Check registered under the duplicated name wins everywhere.
    assert registry.get("Dup") is first
    # A warning naming the duplicated identifier was emitted at WARNING level.
    assert any("Dup" in record.message for record in caplog.records)
    assert any(record.levelno == logging.WARNING for record in caplog.records)

    if register_later:
        # Registration continued past the duplicate, and later checks still resolve.
        assert registry.registered_checks() == [first, later]
        assert registry.get("Later") is later
    else:
        assert registry.registered_checks() == [first]


@pytest.mark.parametrize(
    "applicability, expected_not_applicable_idx",
    [
        ([True, True], []),
        ([False], [0]),
        ([True, False, True, False], [1, 3]),
        ([], []),
    ],
    ids=[
        "all-applicable",
        "none-applicable",
        "mixed-preserves-registration-order",
        "empty-registry",
    ],
)
def test_select_checks_partitions_by_applicability(applicability, expected_not_applicable_idx):
    registry = Registry()
    checks = [FakeCheck("Check{}".format(i), applicable=is_applicable) for i, is_applicable in enumerate(applicability)]
    for check in checks:
        registry.register(check)

    registered, not_applicable, not_approved = registry.select_checks(sample_context())
    assert registered == checks
    assert not_applicable == [checks[i] for i in expected_not_applicable_idx]
    assert not_approved == []


@pytest.mark.parametrize(
    "confirmed, expected_not_approved",
    [(True, False), (False, True)],
    ids=["accepted-runs", "declined-goes-to-not-approved"],
)
def test_select_checks_routes_confirmation_required_check(monkeypatch, confirmed, expected_not_approved):
    registry = Registry()
    needs_approval = FakeCheck("Confirmable", approval=True)
    registry.register(needs_approval)

    monkeypatch.setattr(registry_module.click, "confirm", lambda *_a, **_k: confirmed)
    registered, not_applicable, not_approved = registry.select_checks(sample_context())

    assert registered == [needs_approval]
    assert not_applicable == []
    assert not_approved == ([needs_approval] if expected_not_approved else [])


@pytest.mark.parametrize(
    "identifier",
    [
        "ReservedUsersAndGroups",
        "CriticalPathsHaveExpectedPermissions",
        "CfnHup",
    ],
)
def test_default_registry_wires_in_permission_checks(identifier):
    assert registry_module.DEFAULT_REGISTRY.get(identifier) is not None


def test_default_registry_does_not_register_sample_check():
    assert registry_module.DEFAULT_REGISTRY.get("SampleCheck") is None


def test_default_registry_wires_in_lustre_but_not_the_target_deep_probe():
    assert registry_module.DEFAULT_REGISTRY.get("LustreFilesystem") is not None
    assert registry_module.DEFAULT_REGISTRY.get("FsxTargetsAreReachable") is None
