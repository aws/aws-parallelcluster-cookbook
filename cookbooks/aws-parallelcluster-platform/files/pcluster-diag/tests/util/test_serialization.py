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

"""Unit tests for the generic dataclass serialization helpers."""

import json

from pcluster_diag.util.serialization import to_dict, to_json
from tests.sample_data import sample_context, sample_result


def test_to_dict_converts_enum_fields_to_their_value():
    context = sample_context()

    data = to_dict(context)

    # Enum fields serialize to their value, not the enum member.
    assert data["node_type"] == context.node_type.value
    assert data["pcluster_version"] == context.pcluster_version
    assert data["pcluster_diag_version"] == context.pcluster_diag_version


def test_to_json_is_deterministic_and_valid_json():
    result = sample_result(check_id="C")

    text = to_json(result)

    # Two serializations of the same object are identical, and the output is valid JSON.
    assert to_json(result) == text
    assert json.loads(text)["status"] == result.status.value
