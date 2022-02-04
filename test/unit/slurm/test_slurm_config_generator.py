import os

import pytest
import slurm
from assertpy import assert_that
from slurm.pcluster_slurm_config_generator import generate_slurm_config_files


@pytest.mark.parametrize(
    "no_gpu",
    [False, True],
)
def test_generate_slurm_config_files(mocker, test_datadir, tmpdir, no_gpu):
    input_file = str(test_datadir / "sample_input.yaml")
    instance_types_data = str(test_datadir / "sample_instance_types_data.json")

    mocker.patch("slurm.pcluster_slurm_config_generator.gethostname", return_value="ip-1-0-0-0", autospec=True)
    mocker.patch(
        "slurm.pcluster_slurm_config_generator._get_head_node_private_ip", return_value="ip.1.0.0.0", autospec=True
    )
    template_directory = os.path.dirname(slurm.__file__) + "/templates"
    generate_slurm_config_files(
        tmpdir,
        template_directory,
        input_file,
        instance_types_data,
        dryrun=False,
        no_gpu=no_gpu,
        compute_node_bootstrap_timeout=1600,
    )

    for queue in ["efa", "gpu", "multiple_spot"]:
        for file_type in ["partition", "gres"]:
            file_name = f"pcluster/slurm_parallelcluster_{queue}_{file_type}.conf"
            no_nvidia = "_no_gpu" if (queue == "gpu" or file_type == "gres") and no_gpu else ""
            output_file_name = f"pcluster/slurm_parallelcluster_{queue}_{file_type}{no_nvidia}.conf"
            _assert_files_are_equal(tmpdir / file_name, test_datadir / "expected_outputs" / output_file_name)

    for file in ["slurm_parallelcluster.conf", "slurm_parallelcluster_gres.conf"]:
        _assert_files_are_equal(tmpdir / file, test_datadir / "expected_outputs" / file)

    _assert_files_are_equal(
        tmpdir / "pcluster/instance_name_type_mappings.json",
        test_datadir / "expected_outputs/pcluster/instance_name_type_mappings.json",
    )


def _assert_files_are_equal(file, expected_file):
    with open(file, "r") as f, open(expected_file, "r") as exp_f:
        expected_file_content = exp_f.read()
        expected_file_content = expected_file_content.replace("<DIR>", os.path.dirname(file))
        assert_that(f.read()).is_equal_to(expected_file_content)
