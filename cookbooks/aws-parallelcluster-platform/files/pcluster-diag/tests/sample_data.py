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

"""Shared sample data for the test suite: Contexts, Check doubles, and Results."""

from pcluster_diag.models.check import Check
from pcluster_diag.models.check_error import CheckError
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.report import Report
from pcluster_diag.models.result import Result, Status

# --- Contexts -------------------------------------------------------------------------

# The canonical field values every sample Context carries (node type aside).
SAMPLE_TIMESTAMP = "2026-07-01T16-03-48"
SAMPLE_PCLUSTER_VERSION = "3.16.0"
SAMPLE_PCLUSTER_DIAG_VERSION = "1.0.0"
SAMPLE_INSTANCE_ID = "i-0123456789abcdef0"
SAMPLE_HEAD_NODE_INSTANCE_ID = "i-000000000headnode"
SAMPLE_CLUSTER_CONFIG = {"Region": "us-east-1"}


def sample_context(node_type: NodeType = NodeType.HEAD) -> Context:
    """Return a fully-resolved sample Context for ``node_type`` (defaults to the head node)."""
    return Context(
        timestamp=SAMPLE_TIMESTAMP,
        node_type=node_type,
        pcluster_version=SAMPLE_PCLUSTER_VERSION,
        head_node_instance_id=SAMPLE_HEAD_NODE_INSTANCE_ID,
        instance_id=SAMPLE_INSTANCE_ID,
        cluster_config=dict(SAMPLE_CLUSTER_CONFIG),
        dna_json={"cluster": {"node_type": node_type.value}},
        pcluster_diag_version=SAMPLE_PCLUSTER_DIAG_VERSION,
    )


# --- Check doubles --------------------------------------------------------------------

# The message a FakeCheck raises when configured with ``raises=True``.
FAKE_CHECK_RAISE_MESSAGE = "boom raised inside the fake check"


class FakeCheck(Check):
    """A configurable Check double.

    Args:
        identifier: The check identifier (overrides the class-name default).
        description: The description (defaults to one derived from the identifier).
        applicable: What ``should_run`` returns.
        approval: What ``approval_required`` returns.
        status: The Status of the Result ``run`` returns.
        raises: When True, ``run`` raises instead of returning a Result.
        events: When provided, ``should_run`` and ``run`` append ``"should_run:<id>"`` /
            ``"run:<id>"`` so call ordering can be asserted.
    """

    def __init__(
        self,
        identifier="FakeCheck",
        *,
        description=None,
        applicable=True,
        approval=False,
        status=Status.PASSED,
        raises=False,
        events=None,
    ):
        """Initialize the FakeCheck with its configured behavior (see the class docstring)."""
        self._identifier = identifier
        self._description = description if description is not None else "description for {}".format(identifier)
        self._applicable = applicable
        self._approval = approval
        self._status = status
        self._raises = raises
        self._events = events
        self.ran = False

    @property
    def identifier(self) -> str:
        return self._identifier

    @property
    def description(self) -> str:
        return self._description

    def should_run(self, context: Context) -> bool:
        if self._events is not None:
            self._events.append("should_run:{}".format(self._identifier))
        return self._applicable

    def approval_required(self, context: Context) -> bool:
        return self._approval

    def run(self, context: Context) -> Result:
        self.ran = True
        if self._events is not None:
            self._events.append("run:{}".format(self._identifier))
        if self._raises:
            raise RuntimeError(FAKE_CHECK_RAISE_MESSAGE)
        return Result(check_id=self._identifier, check_description=self._description, status=self._status)


# --- Results --------------------------------------------------------------------------


def sample_result(status: Status = Status.PASSED, *, check_id: str = "SampleCheck", errors=None):
    """Return a sample Result with the given status (and optional errors)."""
    return Result(
        check_id=check_id,
        check_description="description for {}".format(check_id),
        status=status,
        errors=errors,
    )


def sample_results():
    """Return one sample Result per Status, spanning absent, plain, and error-bearing shapes."""
    return [
        sample_result(Status.PASSED, check_id="PassedCheck"),
        sample_result(Status.FAILURE, check_id="FailedCheck", errors=[CheckError("E1", "nope")]),
        sample_result(Status.CHECK_ERROR, check_id="ErroredCheck", errors=[CheckError("E0", "RuntimeError: boom")]),
        sample_result(Status.SKIPPED_BY_USER, check_id="SkippedByUserCheck"),
        sample_result(Status.SKIPPED_NOT_APPLICABLE, check_id="SkippedNotApplicableCheck"),
    ]


# --- Reports --------------------------------------------------------------------------


def sample_report(node_type: NodeType = NodeType.HEAD, results=None) -> Report:
    """Return a sample Report for ``node_type``.

    Defaults to a report carrying the full ``sample_results()`` spread; pass ``results`` (e.g. an
    empty list) to override for edge cases such as a report with no executed checks.
    """
    return Report(
        context=sample_context(node_type),
        results=sample_results() if results is None else results,
    )
