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

import pytest

from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.result import Result, Status
from tests.sample_data import sample_context


class _MinimalCheck(Check):
    """A concrete Check that implements only the required abstract methods."""

    @property
    def description(self) -> str:
        return "a minimal check"

    def should_run(self, context: Context) -> bool:
        return context.node_type is NodeType.HEAD

    def run(self, context: Context) -> Result:
        return Result(check_id=self.identifier, check_description=self.description, status=Status.PASSED)


class _ApprovalCheck(_MinimalCheck):
    """A Check that overrides approval_required to require confirmation."""

    def approval_required(self, context: Context) -> bool:
        return True


class _IncompleteCheck(Check):
    """A subclass that leaves ``should_run`` and ``run`` unimplemented."""

    @property
    def description(self) -> str:
        return "missing should_run and run"


@pytest.mark.parametrize(
    "check_cls",
    [Check, _IncompleteCheck],
    ids=["abstract-base", "incomplete-subclass"],
)
def test_abstract_or_incomplete_check_cannot_be_instantiated(check_cls):
    with pytest.raises(TypeError):
        check_cls()  # type: ignore[abstract]


@pytest.mark.parametrize(
    "check, expected_identifier",
    [(_MinimalCheck(), "_MinimalCheck"), (_ApprovalCheck(), "_ApprovalCheck")],
    ids=["minimal", "approval"],
)
def test_identifier_returns_class_simple_name(check, expected_identifier):
    assert check.identifier == expected_identifier


@pytest.mark.parametrize(
    "check, expected_approval",
    [(_MinimalCheck(), False), (_ApprovalCheck(), True)],
    ids=["defaults-to-false", "overridden-to-true"],
)
def test_approval_required_reflects_subclass(check, expected_approval):
    assert check.approval_required(sample_context()) is expected_approval


@pytest.mark.parametrize(
    "node_type, expected_should_run",
    [(NodeType.HEAD, True), (NodeType.COMPUTE, False)],
    ids=["head-runs", "compute-skips"],
)
def test_should_run_evaluates_context(node_type, expected_should_run):
    assert _MinimalCheck().should_run(sample_context(node_type)) is expected_should_run


def test_run_returns_result():
    check = _MinimalCheck()

    result = check.run(sample_context())

    assert isinstance(result, Result)
    assert result.check_id == check.identifier
    assert result.status is Status.PASSED


def test_abstract_method_bodies_raise_not_implemented():
    check = _MinimalCheck()

    with pytest.raises(NotImplementedError):
        Check.description.fget(check)
    with pytest.raises(NotImplementedError):
        Check.run(check, sample_context())
