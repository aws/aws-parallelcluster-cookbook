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

"""Unit tests for the Context model and NodeType enum."""

import pytest

from pcluster_diag.models.context import NodeType
from tests.sample_data import SAMPLE_TIMESTAMP, sample_context


@pytest.mark.parametrize(
    "node_type, expected_value",
    [
        (NodeType.HEAD, "HeadNode"),
        (NodeType.COMPUTE, "ComputeFleet"),
        (NodeType.LOGIN, "LoginNode"),
    ],
    ids=["head", "compute", "login"],
)
def test_node_type_values(node_type, expected_value):
    assert node_type.value == expected_value


def test_context_carries_run_timestamp():
    # The Context records the run timestamp (the same value that names the report file).
    assert sample_context().timestamp == SAMPLE_TIMESTAMP
