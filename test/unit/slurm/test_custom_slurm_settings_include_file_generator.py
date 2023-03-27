# Copyright 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
from slurm.pcluster_custom_slurm_settings_include_file_generator import (
    _generate_complex_parameter,
    _generate_custom_slurm_config_include_files,
    _generate_simple_parameter,
)


@pytest.mark.parametrize(
    "param, output_string",
    [
        # Nodelist with generic parameters
        (
            {
                "NodeName": "test-node[1-100]",
                "CPUs": "16",
                "RealMemory": "8000",
                "TmpDisk": "64000",
            },
            "NodeName=test-node[1-100] CPUs=16 RealMemory=8000 TmpDisk=64000",
        ),
        # Nodelist with generic parameters and different order of keys (although this should not matter in a Python
        # dict)
        (
            {
                "CPUs": "16",
                "NodeName": "test-node[1-100]",
                "RealMemory": "8000",
                "TmpDisk": "64000",
            },
            "NodeName=test-node[1-100] CPUs=16 RealMemory=8000 TmpDisk=64000",
        ),
        # Partition with generic parameters
        (
            {
                "PartitionName": "long",
                "Nodes": "dev[9-17]",
                "MaxTime": "120",
                "AllowGroups": "admin",
            },
            "PartitionName=long Nodes=dev[9-17] MaxTime=120 AllowGroups=admin",
        ),
        # NodeSet with generic parameters (and out-of-order subparameters definition)
        (
            {
                "Feature": "test-feature",
                "NodeSet": "test-nodes",
                "Nodes": "dev[9-17]",
            },
            "NodeSet=test-nodes Feature=test-feature Nodes=dev[9-17]",
        ),
        # Wrong partition definition with unrealistic nodename (lowercase)
        (
            {
                "Nodes": "dev[9-17]",
                "partitionname": "long",
                "nodename": "test-node[1-100]",
                "MaxTime": "120",
                "AllowGroups": "admin",
            },
            "partitionname=long Nodes=dev[9-17] nodename=test-node[1-100] MaxTime=120 AllowGroups=admin",
        ),
    ],
)
def test_generate_complex_parameter(param, output_string):
    assert_that(_generate_complex_parameter(param)).is_equal_to(output_string)


@pytest.mark.parametrize(
    "param, output_string",
    [
        ({"FirstJobId": "65536"}, "FirstJobId=65536"),
        ({"PluginDir": "/usr/local/lib:/usr/local/slurm/lib"}, "PluginDir=/usr/local/lib:/usr/local/slurm/lib"),
        (
            {"SchedulerParaneters": "allow_zero_lic,batch_sched_delay=30,delay_boot=120"},
            "SchedulerParaneters=allow_zero_lic,batch_sched_delay=30,delay_boot=120",
        ),
    ],
)
def test_generate_simple_parameter(param, output_string):
    assert_that(_generate_simple_parameter(param)).is_equal_to(output_string)


@pytest.mark.parametrize(
    "levels",
    [["slurm"]],
)
def test_generate_custom_slurm_settings_include_files(test_datadir, tmpdir, levels):
    input_file = str(test_datadir / "sample_input.yaml")
    _generate_custom_slurm_config_include_files(tmpdir, input_file, dryrun=False)

    for level in levels:
        output_file_name = f"pcluster/custom_slurm_settings_include_file_{level}.conf"
        _assert_files_are_equal(tmpdir / output_file_name, test_datadir / "expected_outputs" / output_file_name)


@pytest.mark.parametrize(
    "levels",
    [["slurm"]],
)
def test_generate_empty_custom_slurm_settings_include_files(test_datadir, tmpdir, levels):
    input_file = str(test_datadir / "sample_input.yaml")
    _generate_custom_slurm_config_include_files(tmpdir, input_file, dryrun=False)

    for level in levels:
        output_file_name = f"pcluster/custom_slurm_settings_include_file_{level}.conf"
        _assert_files_are_equal(tmpdir / output_file_name, test_datadir / "expected_outputs" / output_file_name)


def _assert_files_are_equal(file, expected_file):
    with open(file, "r", encoding="utf-8") as f, open(expected_file, "r", encoding="utf-8") as exp_f:
        expected_file_content = exp_f.read()
        expected_file_content = expected_file_content.replace("<DIR>", os.path.dirname(file))
        assert_that(f.read()).is_equal_to(expected_file_content)
