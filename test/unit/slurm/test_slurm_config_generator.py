import inspect
import os
import pytest
from assertpy import assert_that
from pathlib import Path
from pcluster_slurm_config_generator import generate_slurm_config_files

def _get_template_folder() -> str:
    module_file = inspect.getsourcefile(generate_slurm_config_files)
    template_path = Path(module_file).parent / "templates"
    return str(template_path)

@pytest.mark.parametrize(
    "no_gpu",
    [False, True],
)
def test_generate_slurm_config_files_nogpu(mocker, test_datadir, tmpdir, no_gpu):
    input_file = str(test_datadir / "sample_input.yaml")
    instance_types_data = str(test_datadir / "sample_instance_types_data.json")

    mocker.patch("pcluster_slurm_config_generator.gethostname", return_value="ip-1-0-0-0", autospec=True)
    mocker.patch(
        "pcluster_slurm_config_generator._get_head_node_private_ip", return_value="ip.1.0.0.0", autospec=True
    )
    template_directory = _get_template_folder()
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

    mocker.patch("pcluster_slurm_config_generator.gethostname", return_value="ip-1-0-0-0", autospec=True)
    mocker.patch(
        "pcluster_slurm_config_generator._get_head_node_private_ip", return_value="ip.1.0.0.0", autospec=True
    )
    template_directory = _get_template_folder()
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
    "slurm_accounting",
    [(False), (True)],
)
def test_generate_slurm_config_files_slurm_accounting(mocker, test_datadir, tmpdir, slurm_accounting):
    if slurm_accounting:
        input_file = str(test_datadir / "sample_input_slurm_accounting.yaml")
    else:
        input_file = str(test_datadir / "sample_input.yaml")
    instance_types_data = str(test_datadir / "sample_instance_types_data.json")

    mocker.patch("pcluster_slurm_config_generator.gethostname", return_value="ip-1-0-0-0", autospec=True)
    mocker.patch(
        "pcluster_slurm_config_generator._get_head_node_private_ip", return_value="ip.1.0.0.0", autospec=True
    )
    template_directory = _get_template_folder()
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

    for file_type in ["", "_slurmdbd"]:
        file_name = f"slurm_parallelcluster{file_type}.conf"
        postfix = "_slurm_accounting" if slurm_accounting else ""
        output_file_name = f"slurm_parallelcluster{file_type}{postfix}.conf"
        _assert_files_are_equal(tmpdir / file_name, test_datadir / "expected_outputs" / output_file_name)


def test_generating_slurm_config_flexible_instance_types(mocker, test_datadir, tmpdir):
    mocker.patch("pcluster_slurm_config_generator.gethostname", return_value="ip-1-0-0-0", autospec=True)
    mocker.patch(
        "pcluster_slurm_config_generator._get_head_node_private_ip", return_value="ip.1.0.0.0", autospec=True
    )

    input_file = os.path.join(test_datadir, "sample_input.yaml")
    instance_types_data = os.path.join(test_datadir, "sample_instance_types_data.json")

    template_directory = _get_template_folder()
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


def _assert_files_are_equal(file, expected_file):
    with open(file, "r", encoding="utf-8") as f, open(expected_file, "r", encoding="utf-8") as exp_f:
        expected_file_content = exp_f.read()
        expected_file_content = expected_file_content.replace("<DIR>", os.path.dirname(file))
        assert_that(f.read()).is_equal_to(expected_file_content)
