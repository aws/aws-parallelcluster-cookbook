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

"""Unit tests for the node attributes reader."""

import json

import pytest

from pcluster_diag.util.node_attributes import attribute, load_node_attributes


def _write(tmp_path, content):
    path = tmp_path / "node_attributes.json"
    path.write_text(content if isinstance(content, str) else json.dumps(content), encoding="utf-8")
    return str(path)


def test_load_returns_the_default_level(tmp_path):
    path = _write(
        tmp_path,
        {
            "default": {"cluster": {"efa": {"version": "1.0.0"}, "slurm": {"version": "25-11-8-1"}}},
            "normal": {"cluster": {"efa": {"version": "1.1.0"}}},
            "override": {"cluster": {"nvidia": {"driver_version": "595.71.05"}}},
            "automatic": {"platform": "amazon"},
            "run_list": ["recipe[x]"],
        },
    )

    attributes = load_node_attributes(path)

    # The other precedence levels are ignored.
    assert attributes == {"cluster": {"efa": {"version": "1.0.0"}, "slurm": {"version": "25-11-8-1"}}}


def test_load_tolerates_a_missing_default_level(tmp_path):
    assert load_node_attributes(_write(tmp_path, {"normal": {"a": 1}})) == {}


@pytest.mark.parametrize("content", ["[1, 2]", {"default": [1, 2]}])
def test_load_rejects_non_object(tmp_path, content):
    with pytest.raises(ValueError):
        load_node_attributes(_write(tmp_path, content))


def test_load_raises_when_file_missing(tmp_path):
    with pytest.raises(OSError):
        load_node_attributes(str(tmp_path / "missing.json"))


@pytest.mark.parametrize(
    "keys, expected",
    [
        (("cluster", "efa", "version"), "1.49.0"),
        (("cluster", "efa"), {"version": "1.49.0"}),
        (("cluster", "nvidia", "driver_version"), None),
        (("cluster", "efa", "version", "deeper"), None),
    ],
)
def test_attribute_walks_the_path(keys, expected):
    assert attribute({"cluster": {"efa": {"version": "1.49.0"}}}, *keys) == expected
