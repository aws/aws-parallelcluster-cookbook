# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with
# the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

import os

import pytest
from assertpy import assert_that
from pcluster_topology_generator import (
    _is_capacity_block,
    _is_gb200,
    cleanup_topology_config_file,
    generate_topology_config_file,
)


def _assert_files_are_equal(file, expected_file):
    with open(file, "r", encoding="utf-8") as f, open(expected_file, "r", encoding="utf-8") as exp_f:
        assert_that(f.read()).is_equal_to(exp_f.read())


@pytest.mark.parametrize(
    "file_name_suffix, force_configuration",
    [
        ("with_capacity_block", False),
        ("no_capacity_block", False),
        ("with_capacity_block", True),
        ("no_capacity_block", True),
    ],
)
def test_generate_topology_config(test_datadir, tmpdir, file_name_suffix, force_configuration):
    block_sizes = "9,18" if "no" not in file_name_suffix else None
    force_suffix = "_force" if force_configuration else ""
    file_name = "sample_" + file_name_suffix + ".yaml"
    input_file_path = str(test_datadir / file_name)
    output_file_name = "topology_" + file_name_suffix + force_suffix + ".conf"
    output_file_path = f"{tmpdir}/{output_file_name}"
    generate_topology_config_file(output_file_path, input_file_path, block_sizes, force_configuration)
    if "no" in file_name_suffix:
        assert_that(os.path.isfile(output_file_path)).is_equal_to(False)
    else:
        _assert_files_are_equal(output_file_path, test_datadir / "expected_outputs" / output_file_name)


@pytest.mark.parametrize("file_exists", [True, False])
def test_cleanup_topology_config_file(mocker, tmpdir, file_exists):
    topology_file_path = tmpdir / "topology.conf"
    mocker.patch("os.path.exists", return_value=file_exists)
    mock_remove = mocker.patch("os.remove")
    cleanup_topology_config_file(str(topology_file_path))
    if file_exists:
        mock_remove.assert_called_once_with(str(topology_file_path))
    else:
        mock_remove.assert_not_called()


@pytest.mark.parametrize(
    "capacity_type, expected_result",
    [
        ("capacity-block", True),
        ("on-demand", False),
        ("spot", False),
        ("any-value", False),
        ("bla-capacity-block-bla", False),
    ],
)
def test_is_capacity_block(capacity_type, expected_result):
    assert_that(_is_capacity_block(capacity_type)).is_equal_to(expected_result)


@pytest.mark.parametrize(
    "instance_type, expected_result",
    [
        ("p6e-gb200.ANY_SIZE", True),
        ("NOTp6e-gb200.ANY_SIZE", False),
        ("p6e-b200.ANY_SIZE", False),
        ("any-value", False),
    ],
)
def test_is_gb200(instance_type, expected_result):
    assert_that(_is_gb200(instance_type)).is_equal_to(expected_result)
