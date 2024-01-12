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

import json
import os

import pytest
from assertpy import assert_that
from config_utils import get_template_folder
from pcluster_slurm_config_generator import generate_slurm_config_files


def _mock_head_node_config(mocker):
    mocker.patch("pcluster_slurm_config_generator.gethostname", return_value="ip-1-0-0-0", autospec=True)
    mocker.patch("pcluster_slurm_config_generator._get_head_node_private_ip", return_value="ip.1.0.0.0", autospec=True)


@pytest.mark.parametrize(
    "no_gpu",
    [False, True],
)
def test_generate_slurm_config_files_nogpu(mocker, test_datadir, tmpdir, no_gpu):
    input_file = str(test_datadir / "sample_input.yaml")
    instance_types_data = str(test_datadir / "sample_instance_types_data.json")

    _mock_head_node_config(mocker)
    template_directory = get_template_folder()
    generate_slurm_config_files(
        tmpdir,
        template_directory,
        input_file,
        instance_types_data,
        dryrun=False,
        no_gpu=no_gpu,
        compute_node_bootstrap_timeout=1600,
        realmemory_to_ec2memory_ratio=0.95,
        slurmdbd_user="slurm",
        cluster_name="test-cluster",
    )

    for queue in ["efa", "gpu", "multiple_spot"]:
        for file_type in ["partition", "gres"]:
            file_name = f"pcluster/slurm_parallelcluster_{queue}_{file_type}.conf"
            no_nvidia = "_no_gpu" if (queue == "gpu" or file_type == "gres") and no_gpu else ""
            output_file_name = f"pcluster/slurm_parallelcluster_{queue}_{file_type}{no_nvidia}.conf"
            _assert_files_are_equal(tmpdir / file_name, test_datadir / "expected_outputs" / output_file_name)

    for file_type in ["", "_gres", "_cgroup"]:
        output_file_name = f"slurm_parallelcluster{file_type}.conf"
        _assert_files_are_equal(tmpdir / output_file_name, test_datadir / "expected_outputs" / output_file_name)


@pytest.mark.parametrize(
    "memory_scheduling,realmemory_to_ec2memory_ratio",
    [(False, 0.95), (True, 0.90)],
)
def test_generate_slurm_config_files_memory_scheduling(
    mocker, test_datadir, tmpdir, memory_scheduling, realmemory_to_ec2memory_ratio
):
    if memory_scheduling:
        input_file = str(test_datadir / "sample_input_mem_sched.yaml")
    else:
        input_file = str(test_datadir / "sample_input.yaml")
    instance_types_data = str(test_datadir / "sample_instance_types_data.json")

    _mock_head_node_config(mocker)
    template_directory = get_template_folder()
    generate_slurm_config_files(
        tmpdir,
        template_directory,
        input_file,
        instance_types_data,
        dryrun=False,
        no_gpu=False,
        compute_node_bootstrap_timeout=1600,
        realmemory_to_ec2memory_ratio=realmemory_to_ec2memory_ratio,
        slurmdbd_user="slurm",
        cluster_name="test-cluster",
    )

    for queue in ["efa", "gpu", "multiple_spot"]:
        for file_type in ["partition", "gres"]:
            file_name = f"pcluster/slurm_parallelcluster_{queue}_{file_type}.conf"
            no_nvidia = ""
            mem_sched = "_mem_sched" if (memory_scheduling and file_type == "partition") else ""
            output_file_name = f"pcluster/slurm_parallelcluster_{queue}_{file_type}{no_nvidia}{mem_sched}.conf"
            _assert_files_are_equal(tmpdir / file_name, test_datadir / "expected_outputs" / output_file_name)

    for file_type in ["", "_gres", "_cgroup"]:
        file_name = f"slurm_parallelcluster{file_type}.conf"
        mem_sched = "_mem_sched" if memory_scheduling else ""
        output_file_name = f"slurm_parallelcluster{file_type}{mem_sched}.conf"
        _assert_files_are_equal(tmpdir / file_name, test_datadir / "expected_outputs" / output_file_name)


@pytest.mark.parametrize(
    "input_config, expected_outputs",
    [
        pytest.param(
            "sample_input.yaml",
            [
                "slurm_parallelcluster.conf",
                "slurm_parallelcluster_slurmdbd.conf",
            ],
            id="Case without Slurm Accounting",
        ),
        pytest.param(
            "sample_input_slurm_accounting.yaml",
            [
                "slurm_parallelcluster_slurm_accounting.conf",
                "slurm_parallelcluster_slurmdbd_slurm_accounting.conf",
            ],
            id="Case with Slurm Accounting",
        ),
        pytest.param(
            "sample_input_slurm_accounting_dbname.yaml",
            [
                "slurm_parallelcluster_slurm_accounting_dbname.conf",
                "slurm_parallelcluster_slurmdbd_slurm_accounting_dbname.conf",
            ],
            id="Case with Slurm Accounting passing DatabaseName",
        ),
        pytest.param(
            "sample_input_externaldbd.yaml",
            # Here we don't care about the include file for the slurmdbd.conf, because slurmdbd is not going
            # to be launched on the PC cluster (even if our current recipes may still generate it empty).
            [
                "slurm_parallelcluster_externaldbd.conf",
            ],
            id="Case with Slurmdbd daemon external to the cluster",
        ),
    ],
)
def test_generate_slurm_config_files_slurm_accounting(mocker, test_datadir, tmpdir, input_config, expected_outputs):
    input_file = str(test_datadir / input_config)
    instance_types_data = str(test_datadir / "sample_instance_types_data.json")

    _mock_head_node_config(mocker)
    template_directory = get_template_folder()
    generate_slurm_config_files(
        tmpdir,
        template_directory,
        input_file,
        instance_types_data,
        dryrun=False,
        no_gpu=False,
        compute_node_bootstrap_timeout=1600,
        realmemory_to_ec2memory_ratio=0.95,
        slurmdbd_user="slurm",
        cluster_name="test-cluster",
    )

    generated_outputs = ["slurm_parallelcluster.conf", "slurm_parallelcluster_slurmdbd.conf"]

    for item in zip(generated_outputs, expected_outputs):
        generated_file = str(tmpdir / item[0])
        expected_file = str(test_datadir / "expected_outputs" / item[1])
        _assert_files_are_equal(generated_file, expected_file)


def test_generating_slurm_config_flexible_instance_types(mocker, test_datadir, tmpdir):
    _mock_head_node_config(mocker)

    input_file = os.path.join(test_datadir, "sample_input.yaml")
    instance_types_data = os.path.join(test_datadir, "sample_instance_types_data.json")

    template_directory = get_template_folder()
    generate_slurm_config_files(
        tmpdir,
        template_directory,
        input_file,
        instance_types_data,
        dryrun=False,
        no_gpu=False,
        compute_node_bootstrap_timeout=1600,
        realmemory_to_ec2memory_ratio=0.95,
        slurmdbd_user="slurm",
        cluster_name="test-cluster",
    )

    for queue in ["queue1", "queue2", "queue3", "queue4", "queue5", "queue6", "queue7", "queue8"]:
        for file_type in ["partition", "gres"]:
            file_name = f"pcluster/slurm_parallelcluster_{queue}_{file_type}.conf"
            output_file_name = f"pcluster/slurm_parallelcluster_{queue}_{file_type}.conf"
            _assert_files_are_equal(tmpdir / file_name, test_datadir / "expected_outputs" / output_file_name)

    for file_type in ["", "_gres", "_cgroup"]:
        file_name = f"slurm_parallelcluster{file_type}.conf"
        output_file_name = f"slurm_parallelcluster{file_type}.conf"
        _assert_files_are_equal(tmpdir / file_name, test_datadir / "expected_outputs" / output_file_name)


def test_generate_slurm_config_with_custom_settings(mocker, test_datadir, tmpdir):
    _mock_head_node_config(mocker)

    input_file = os.path.join(test_datadir, "sample_input.yaml")
    instance_types_data = os.path.join(test_datadir, "sample_instance_types_data.json")

    template_directory = get_template_folder()
    generate_slurm_config_files(
        tmpdir,
        template_directory,
        input_file,
        instance_types_data,
        dryrun=False,
        no_gpu=False,
        compute_node_bootstrap_timeout=1600,
        realmemory_to_ec2memory_ratio=0.95,
        slurmdbd_user="slurm",
        cluster_name="test-cluster",
    )

    for queue in ["efa", "gpu", "multiple_spot"]:
        file_name = f"pcluster/slurm_parallelcluster_{queue}_partition.conf"
        output_file_name = f"pcluster/slurm_parallelcluster_{queue}_partition.conf"
        _assert_files_are_equal(tmpdir / file_name, test_datadir / "expected_outputs" / output_file_name)


def test_generate_slurm_config_with_job_exc_alloc(mocker, test_datadir, tmpdir):
    _mock_head_node_config(mocker)

    input_file = os.path.join(test_datadir, "cluster_config.yaml")
    instance_types_data = os.path.join(test_datadir, "sample_instance_types_data.json")

    template_directory = get_template_folder()
    generate_slurm_config_files(
        tmpdir,
        template_directory,
        input_file,
        instance_types_data,
        dryrun=False,
        no_gpu=False,
        compute_node_bootstrap_timeout=1600,
        realmemory_to_ec2memory_ratio=0.95,
        slurmdbd_user="slurm",
        cluster_name="test-cluster",
    )

    for queue in ["queue_jls_enabled", "queue_jls_disabled", "queue_jls_default"]:
        file_name = f"pcluster/slurm_parallelcluster_{queue}_partition.conf"
        output_file_name = f"pcluster/slurm_parallelcluster_{queue}_partition.conf"
        _assert_files_are_equal(tmpdir / file_name, test_datadir / "expected_outputs" / output_file_name)


def test_generate_partition_nodelist_mapping(mocker, test_datadir, tmpdir):
    mocker.patch("pcluster_slurm_config_generator.gethostname", return_value="ip-1-0-0-0", autospec=True)
    mocker.patch("pcluster_slurm_config_generator._get_head_node_private_ip", return_value="ip.1.0.0.0", autospec=True)

    input_file = os.path.join(test_datadir, "sample_input.yaml")
    instance_types_data = os.path.join(test_datadir, "sample_instance_types_data.json")

    template_directory = get_template_folder()
    generate_slurm_config_files(
        tmpdir,
        template_directory,
        input_file,
        instance_types_data,
        dryrun=False,
        no_gpu=False,
        compute_node_bootstrap_timeout=1600,
        realmemory_to_ec2memory_ratio=0.95,
        slurmdbd_user="slurm",
        cluster_name="test-cluster",
    )

    filename = "pcluster/parallelcluster_partition_nodelist_mapping.json"
    with open(os.path.join(tmpdir, filename), "r", encoding="utf-8") as file:
        output_mapping = json.load(file)
    with open(os.path.join(test_datadir, "expected_outputs", filename), "r", encoding="utf-8") as file:
        expected_mapping = json.load(file)
    assert_that(output_mapping).is_equal_to(expected_mapping)


def _assert_files_are_equal(file, expected_file):
    with open(file, "r", encoding="utf-8") as f, open(expected_file, "r", encoding="utf-8") as exp_f:
        expected_file_content = exp_f.read()
        expected_file_content = expected_file_content.replace("<DIR>", os.path.dirname(file))
        file_content = f.read()
        assert_that(file_content).is_equal_to(expected_file_content)
