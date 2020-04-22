import json
import os

from assertpy import assert_that
from jsonschema import validate
from slurm.pcluster_slurm_config_generator import (
    _get_jinja_env,
    _load_queues_info,
    _render_queue_configs,
    _render_slurm_parallelcluster_configs,
)

INPUT_SCHEMA = {
    "type": "object",
    "properties": {
        "queues_config": {
            "type": "object",
            "patternProperties": {
                "^[a-zA-Z0-9-]+$": {
                    "type": "object",
                    "properties": {
                        "instances": {
                            "type": "object",
                            "patternProperties": {
                                "^[a-z0-9.]+$": {
                                    "type": "object",
                                    "properties": {
                                        "static_size": {"type": "integer"},
                                        "dynamic_size": {"type": "integer"},
                                        "vcpus": {"type": "integer"},
                                        "gpus": {"type": "integer"},
                                        "spot_price": {"type": "number"},
                                    },
                                    "additionalProperties": False,
                                    "required": ["static_size", "dynamic_size", "vcpus", "gpus"],
                                }
                            },
                        },
                        "placement_group": {"type": "string"},
                        "enable_efa": {"type": "boolean"},
                        "disable_hyperthreading": {"type": "boolean"},
                        "compute_type": {"type": "string"},
                        "is_default": {"type": "boolean"},
                    },
                    "additionalProperties": False,
                    "required": ["instances"],
                }
            },
            "additionalProperties": False,
        },
        "scaling_config": {
            "type": "object",
            "properties": {"scaledown_idletime": {"type": "integer"}},
            "required": ["scaledown_idletime"],
        },
    },
    "additionalProperties": False,
    "required": ["queues_config", "scaling_config"],
}


def test_input_file_format():
    queues_info = _get_default_input(load_raw=True)
    validate(instance=queues_info, schema=INPUT_SCHEMA)


def test_default_input(mocker, test_datadir):
    mocker.patch("slurm.pcluster_slurm_config_generator.gethostname", return_value="ip-1-0-0-0", autospec=True)
    mocker.patch("slurm.pcluster_slurm_config_generator.getfqdn", return_value="ip.1.0.0.0", autospec=True)
    env = _get_jinja_env(os.path.abspath("files/default/slurm/templates"))
    queues_info = _get_default_input()
    _test_generate_queue_configs(queues_info, env, os.path.join(test_datadir, "expected_outputs"))
    _test_generate_slurm_pcluster_configs(queues_info, env, os.path.join(test_datadir, "expected_outputs"))


def _get_default_input(load_raw=False):
    filepath = os.path.abspath("test/unit/slurm/test_slurm_config_generator/sample_input.json")
    return json.load(open(filepath)) if load_raw else _load_queues_info(filepath)


def _test_generate_queue_configs(queues_info, env, datadir):
    for queue in queues_info["queues_config"]:
        for file_type in ["partition", "gres"]:
            rendered_template = _render_queue_configs(queues_info, queue, file_type, env, "test_outputs/pcluster")
            with open(
                os.path.join(datadir, "pcluster", "slurm_parallelcluster_{}_{}.conf".format(queue, file_type)), "r"
            ) as expected_file:
                expected = expected_file.read()
            assert_that(rendered_template).is_equal_to(expected)


def _test_generate_slurm_pcluster_configs(queues_info, env, datadir):
    for template_name in ["slurm_parallelcluster.conf", "slurm_parallelcluster_gres.conf"]:
        rendered_template = _render_slurm_parallelcluster_configs(queues_info, template_name, env)
        with open(os.path.join(datadir, template_name), "r") as expected_file:
            expected = expected_file.read()
        assert_that(rendered_template).is_equal_to(expected)
