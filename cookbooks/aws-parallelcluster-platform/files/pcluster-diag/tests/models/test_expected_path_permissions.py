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

"""Unit tests for the expected-path-permissions model."""

import pytest

from pcluster_diag.core.constants import GROUP_OTHER_WRITE, OWNER_READ, OWNER_WRITE
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.expected_path_permissions import ExpectedPathPermissions

_HEAD = (NodeType.HEAD,)


def _expectation(**kwargs) -> ExpectedPathPermissions:
    """Build an expectation for ``/path``, defaulting to a single required bit."""
    kwargs.setdefault("required_bits", OWNER_READ)
    return ExpectedPathPermissions("/path", "owner", "group", _HEAD, **kwargs)


def test_rejects_expectation_that_would_never_inspect_the_mode():
    # Without any of the three mode expectations the mode would be silently unchecked.
    with pytest.raises(ValueError, match="never inspected"):
        ExpectedPathPermissions("/path", "owner", "group", _HEAD)


def test_rejects_empty_allowed_modes():
    with pytest.raises(ValueError, match="must not be empty"):
        ExpectedPathPermissions("/path", "owner", "group", _HEAD, allowed_modes=frozenset())


def test_rejects_allowed_modes_combined_with_bits():
    # allowed_modes short-circuits the bit checks, so declaring both hides the bits.
    with pytest.raises(ValueError, match="cannot be combined"):
        ExpectedPathPermissions(
            "/path", "owner", "group", _HEAD, required_bits=OWNER_READ, allowed_modes=frozenset({"0600"})
        )


def test_rejects_bit_that_is_both_required_and_forbidden():
    with pytest.raises(ValueError, match="0200 is both required and forbidden"):
        _expectation(required_bits=OWNER_WRITE, forbidden_bits=OWNER_WRITE)


@pytest.mark.parametrize(
    "mode, expected_missing",
    [("0600", 0), ("0400", 0), ("0200", OWNER_READ), ("0000", OWNER_READ)],
)
def test_missing_bits(mode, expected_missing):
    assert _expectation(required_bits=OWNER_READ).missing_bits(mode) == expected_missing


@pytest.mark.parametrize(
    "mode, expected_offending",
    [("0600", 0), ("0620", 0o020), ("0602", 0o002), ("0622", 0o022)],
)
def test_offending_bits(mode, expected_offending):
    expectation = _expectation(required_bits=OWNER_READ, forbidden_bits=GROUP_OTHER_WRITE)

    assert expectation.offending_bits(mode) == expected_offending


def test_bit_checks_ignore_setuid_setgid_and_sticky_bits():
    # stat reports the full 07777 mode; those bits are outside both expectations and must not leak in.
    expectation = _expectation(required_bits=OWNER_READ, forbidden_bits=GROUP_OTHER_WRITE)

    assert expectation.missing_bits("4600") == 0
    assert expectation.offending_bits("7600") == 0


def test_is_disallowed_mode_is_false_without_allowed_modes():
    assert _expectation().is_disallowed_mode("0777") is False


@pytest.mark.parametrize("mode, disallowed", [("0600", False), ("0640", False), ("0400", True), ("0644", True)])
def test_is_disallowed_mode(mode, disallowed):
    expectation = _expectation(required_bits=0, allowed_modes=frozenset({"0600", "0640"}))

    assert expectation.is_disallowed_mode(mode) is disallowed


def test_allowed_modes_description_is_ordered_numerically():
    expectation = _expectation(required_bits=0, allowed_modes=frozenset({"0640", "0600"}))

    assert expectation.allowed_modes_description() == "0600 or 0640"


def test_allowed_modes_description_is_empty_without_allowed_modes():
    assert _expectation().allowed_modes_description() == ""


def test_rejects_severity_flag_without_forbidden_bits():
    with pytest.raises(ValueError, match="forbidden_bits_break_daemon without forbidden_bits"):
        _expectation(forbidden_bits_break_daemon=True)


def test_forbidden_bits_are_advisory_by_default():
    assert _expectation(forbidden_bits=GROUP_OTHER_WRITE).forbidden_bits_break_daemon is False
