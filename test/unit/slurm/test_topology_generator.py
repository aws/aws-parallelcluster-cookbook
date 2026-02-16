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
    build_topology_block_mapping,
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
    "cluster_config, block_sizes, force_configuration, expected_mapping",
    [
        pytest.param(
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "CAPACITY_BLOCK",
                            "ComputeResources": [
                                {"Name": "cr1", "MinCount": 1, "MaxCount": 1, "InstanceType": "p6e-gb200.ANY_SIZE"},
                            ],
                        }
                    ]
                }
            },
            None,
            False,
            {},
            id="no block_sizes returns empty mapping",
        ),
        pytest.param(
            {"Scheduling": {"SlurmQueues": []}},
            "",
            False,
            {},
            id="empty block_sizes returns empty mapping",
        ),
        pytest.param(
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "ONDEMAND",
                            "ComputeResources": [
                                {"Name": "cr1", "MinCount": 10, "MaxCount": 10, "InstanceType": "ANY_INSTANCE"},
                            ],
                        }
                    ]
                }
            },
            "10",
            False,
            {},
            id="on-demand without force_configuration returns empty",
        ),
        pytest.param(
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "ONDEMAND",
                            "ComputeResources": [
                                {"Name": "cr1", "MinCount": 10, "MaxCount": 10, "InstanceType": "ANY_INSTANCE"},
                            ],
                        }
                    ]
                }
            },
            "10",
            True,
            {("q1", "cr1"): "Block1"},
            id="force_configuration bypasses capacity block and instance type checks",
        ),
        pytest.param(
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "CAPACITY_BLOCK",
                            "ComputeResources": [
                                {"Name": "cr1", "MinCount": 5, "MaxCount": 10, "InstanceType": "p6e-gb200.ANY_SIZE"},
                            ],
                        }
                    ]
                }
            },
            "10",
            False,
            {},
            id="dynamic nodes (MinCount != MaxCount) are skipped",
        ),
        pytest.param(
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "my-st-queue",
                            "CapacityType": "CAPACITY_BLOCK",
                            "ComputeResources": [
                                {
                                    "Name": "my-dy-cr",
                                    "MinCount": 9,
                                    "MaxCount": 9,
                                    "InstanceType": "p6e-gb200.ANY_SIZE",
                                },
                                {"Name": "cr2", "MinCount": 18, "MaxCount": 18, "InstanceType": "p6e-gb200.ANY_SIZE"},
                            ],
                        },
                        {
                            "Name": "q2",
                            "CapacityType": "CAPACITY_BLOCK",
                            "ComputeResources": [
                                {"Name": "cr3", "MinCount": 9, "MaxCount": 9, "InstanceType": "p6e-gb200.ANY_SIZE"},
                            ],
                        },
                    ]
                }
            },
            "9,18",
            False,
            {("my-st-queue", "my-dy-cr"): "Block1", ("my-st-queue", "cr2"): "Block2", ("q2", "cr3"): "Block3"},
            id="multiple queues and CRs with st/dy in names get sequential block names",
        ),
        pytest.param(
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "CAPACITY_BLOCK",
                            "ComputeResources": [
                                {"Name": "cr1", "MinCount": 5, "MaxCount": 5, "InstanceType": "p6e-gb200.ANY_SIZE"},
                            ],
                        }
                    ]
                }
            },
            "9,18",
            False,
            {},
            id="block size mismatch returns empty",
        ),
    ],
)
def test_build_topology_block_mapping(cluster_config, block_sizes, force_configuration, expected_mapping):
    """Test build_topology_block_mapping returns correct mapping."""
    result = build_topology_block_mapping(cluster_config, block_sizes, force_configuration)
    assert_that(result).is_equal_to(expected_mapping)


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
