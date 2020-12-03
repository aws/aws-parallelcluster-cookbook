import json
import os

import slurm
from assertpy import assert_that
from jsonschema import validate
from slurm.pcluster_slurm_config_generator import generate_slurm_config_files

INPUT_SCHEMA = {
    "type": "object",
    "properties": {
        "cluster": {
            "type": "object",
            "properties": {
                "queue_settings": {
                    "type": "object",
                    "patternProperties": {
                        "^[a-zA-Z0-9-_]+$": {
                            "type": "object",
                            "properties": {
                                "compute_resource_settings": {
                                    "type": "object",
                                    "patternProperties": {
                                        "^[a-zA-Z0-9-]+$": {
                                            "type": "object",
                                            "properties": {
                                                "instance_type": {"type": "string"},
                                                "min_count": {"type": "integer"},
                                                "max_count": {"type": "integer"},
                                                "vcpus": {"type": "integer"},
                                                "gpus": {"type": "integer"},
                                                "spot_price": {"type": "number"},
                                                "enable_efa": {"type": "boolean"},
                                            },
                                            "additionalProperties": False,
                                            "required": ["instance_type", "min_count", "max_count", "vcpus", "gpus"],
                                        }
                                    },
                                },
                                "placement_group": {"type": ["string", "null"]},
                                "enable_efa": {"type": "boolean"},
                                "disable_hyperthreading": {"type": "boolean"},
                                "compute_type": {"type": "string"},
                            },
                            "additionalProperties": False,
                            "required": ["compute_resource_settings"],
                        }
                    },
                    "additionalProperties": False,
                },
                "scaling": {
                    "type": "object",
                    "properties": {"scaledown_idletime": {"type": "integer"}},
                    "required": ["scaledown_idletime"],
                },
                "default_queue": {"type": "string"},
                "label": {"type": "string"},
            },
            "additionalProperties": False,
            "required": ["queue_settings", "scaling", "default_queue", "label"],
        }
    },
    "additionalProperties": False,
    "required": ["cluster"],
}


def _test_input_file_format(input_file):
    cluster_config = json.load(open(input_file))
    validate(instance=cluster_config, schema=INPUT_SCHEMA)


def test_generate_slurm_config_files(mocker, test_datadir, tmpdir):
    input_file = str(test_datadir / "sample_input.json")
    _test_input_file_format(input_file)

    mocker.patch("slurm.pcluster_slurm_config_generator.gethostname", return_value="ip-1-0-0-0", autospec=True)
    mocker.patch(
        "slurm.pcluster_slurm_config_generator._get_head_node_private_ip", return_value="ip.1.0.0.0", autospec=True
    )
    template_directory = os.path.dirname(slurm.__file__) + "/templates"
    generate_slurm_config_files(tmpdir, template_directory, input_file, dryrun=False)

    for queue in ["efa", "gpu", "multiple_spot"]:
        for file_type in ["partition", "gres"]:
            file_name = f"pcluster/slurm_parallelcluster_{queue}_{file_type}.conf"
            _assert_files_are_equal(tmpdir / file_name, test_datadir / "expected_outputs" / file_name)

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
