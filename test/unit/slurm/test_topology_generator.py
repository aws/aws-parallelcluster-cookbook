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

import pytest
import yaml
import os
from assertpy import assert_that
from config_utils import get_template_folder
from unittest.mock import mock_open, patch
from pcluster_topology_generator import (
    generate_topology_config_file,
    CriticalError,
    _load_cluster_config,
)


def _assert_files_are_equal(file, expected_file):
    with open(file, "r", encoding="utf-8") as f, open(expected_file, "r", encoding="utf-8") as exp_f:
        assert_that(f.read()).is_equal_to(exp_f.read())


@pytest.mark.parametrize("file_name_suffix", [
    "with_capacity_block",
    "no_capacity_block"
])
def test_generate_topology_config(test_datadir, tmpdir, file_name_suffix):
    block_sizes = "9,18" #if 'no' not in file_name_suffix else None
    file_name = "sample_" + file_name_suffix + ".yaml"
    input_file_path = str(test_datadir / file_name)
    output_file_name = "topology_" + file_name_suffix + ".conf"
    output_file_path = f"{tmpdir}/{output_file_name}"
    generate_topology_config_file(output_file_path, input_file_path, block_sizes)
    _assert_files_are_equal(output_file_path, test_datadir / "expected_outputs" / output_file_name)



def test_load_cluster_config_file_not_found():
    """Test loading a non-existent configuration file."""
    with pytest.raises(FileNotFoundError):
        _load_cluster_config("nonexistent_file.yaml")


def test_generate_topology_config_missing_key(tmp_path):
    """Test generating topology config with missing required key."""
    invalid_config = {"Scheduling": {}}  # Missing SlurmQueues
    config_path = tmp_path / "invalid_config.yaml"
    with open(config_path, 'w') as f:
        yaml.dump(invalid_config, f)

    output_file = str(tmp_path / "topology.conf")
    with pytest.raises(CriticalError):
        generate_topology_config_file(output_file, str(config_path), "9,18")

