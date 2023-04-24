# Copyright 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
import logging
import os
from types import SimpleNamespace

import health_check_manager
import pytest
from assertpy import assert_that
from health_check_manager import (
    HealthCheckConfig,
    HealthCheckConfigLoader,
    HealthCheckDefinition,
    HealthCheckManagerConfig,
    ManagedHealthCheckName,
)


class TestManagedHealthCheckName:
    """Class to test ManagedHealthCheckName."""

    @pytest.mark.parametrize(
        ("check_name", "health_check_dir", "expected_path"),
        [
            (
                "gpu",
                "/my/path/",
                "/my/path/gpu_health_check.sh",
            ),
            ("gpu", "/my/other/path/", "/my/other/path/gpu_health_check.sh"),
        ],
    )
    def test_get_health_check_path(self, check_name, health_check_dir, expected_path):
        """Test get_health_check_path method."""
        assert_that(ManagedHealthCheckName[check_name.upper()].get_health_check_path(health_check_dir)).is_equal_to(
            expected_path
        )


class TestHealthCheckManagerConfig:
    """Class to test HealthCheckManagerConfig."""

    @pytest.mark.parametrize(
        ("config_file", "expected_attributes"),
        [
            (
                "default.conf",
                {
                    "health_check_timeout": 600,
                    "logging_config": os.path.join(
                        os.path.dirname(health_check_manager.__file__), "logging", "health_check_manager_logging.conf"
                    ),
                    "managed_health_check_dir": "/my/health_checks/",
                },
            ),
            (
                "all_options.conf",
                {
                    "health_check_timeout": 100,
                    "logging_config": "/my/logging/config",
                    "managed_health_check_dir": "/my/checks/",
                },
            ),
            (
                "non-existent",
                {
                    "health_check_timeout": 600,
                    "logging_config": os.path.join(
                        os.path.dirname(health_check_manager.__file__), "logging", "health_check_manager_logging.conf"
                    ),
                    "managed_health_check_dir": os.path.join(
                        os.path.dirname(health_check_manager.__file__), "health_checks"
                    ),
                },
            ),
        ],
        ids=["default", "all_options", "fallback_default"],
    )
    def test_config_parsing(self, config_file, expected_attributes, test_datadir):
        """Test config_parsing method."""
        sync_config = HealthCheckManagerConfig(test_datadir / config_file)
        for key in expected_attributes:
            assert_that(sync_config.__dict__.get(key)).is_equal_to(expected_attributes.get(key))

    def test_config_comparison(self, test_datadir):
        """Test configs comparison."""
        config = test_datadir / "config.conf"
        config_modified = test_datadir / "config_modified.conf"

        assert_that(HealthCheckManagerConfig(config)).is_equal_to(HealthCheckManagerConfig(config))
        assert_that(HealthCheckManagerConfig(config)).is_not_equal_to(HealthCheckManagerConfig(config_modified))


class TestHealthCheckConfigLoader:
    """Class to test HealthCheckConfigLoader."""

    @pytest.mark.parametrize(
        ("conf_file_content", "health_check_dir_path", "params", "expected_health_check_conf"),
        [
            (
                {
                    "Scheduling": {
                        "SlurmQueues": [
                            {
                                "Name": "q1",
                                "HealthChecks": {"Gpu": {"Enabled": None}},
                                "ComputeResources": [
                                    {
                                        "Name": "c1",
                                        "HealthChecks": {"Gpu": {"Enabled": None}},
                                    }
                                ],
                            },
                        ]
                    }
                },
                "/my/path/for/checks",
                {
                    "cluster_configuration": "mocked",
                    "node_type": "ComputeFleet",
                    "queue_name": "q1",
                    "compute_resource_name": "c1",
                },
                HealthCheckConfig(
                    node_type="ComputeFleet",
                    queue_name="q1",
                    compute_resource_name="c1",
                    health_checks=[
                        HealthCheckDefinition(
                            name="Gpu",
                            is_managed=True,
                            is_enabled=False,
                            check_path="/my/path/for/checks/gpu_health_check.sh",
                        )
                    ],
                ),
            ),
            (
                {
                    "Scheduling": {
                        "SlurmQueues": [
                            {
                                "Name": "q1",
                                # missing HealthChecks definition
                                "ComputeResources": [
                                    {
                                        "Name": "c1",
                                        # missing HealthChecks definition
                                    }
                                ],
                            },
                        ]
                    }
                },
                "/my/path/for/checks",
                {
                    "cluster_configuration": "mocked",
                    "node_type": "ComputeFleet",
                    "queue_name": "q1",
                    "compute_resource_name": "c1",
                },
                HealthCheckConfig(
                    node_type="ComputeFleet",
                    queue_name="q1",
                    compute_resource_name="c1",
                    health_checks=[],
                ),
            ),
            (
                {
                    "Scheduling": {
                        "SlurmQueues": [
                            {
                                "Name": "q1",
                                "HealthChecks": {"Gpu": {"Enabled": True}},
                                "ComputeResources": [
                                    {
                                        "Name": "c1",
                                        # missing HealthChecks definition
                                    }
                                ],
                            },
                        ]
                    }
                },
                "/my/path/for/checks",
                {
                    "cluster_configuration": "mocked",
                    "node_type": "ComputeFleet",
                    "queue_name": "q1",
                    "compute_resource_name": "c1",
                },
                HealthCheckConfig(
                    node_type="ComputeFleet",
                    queue_name="q1",
                    compute_resource_name="c1",
                    health_checks=[],
                ),
            ),
            (
                {
                    "Scheduling": {
                        "SlurmQueues": [
                            {
                                "Name": "q1",
                                "HealthChecks": {"Gpu": {"Enabled": False}},
                                "ComputeResources": [
                                    {
                                        "Name": "c1",
                                        "HealthChecks": {"Gpu": {"Enabled": True}},
                                    }
                                ],
                            },
                        ]
                    }
                },
                "/my/path/for/checks",
                {
                    "cluster_configuration": "mocked",
                    "node_type": "ComputeFleet",
                    "queue_name": "q1",
                    "compute_resource_name": "c1",
                },
                HealthCheckConfig(
                    node_type="ComputeFleet",
                    queue_name="q1",
                    compute_resource_name="c1",
                    health_checks=[
                        HealthCheckDefinition(
                            name="Gpu",
                            is_managed=True,
                            is_enabled=True,
                            check_path="/my/path/for/checks/gpu_health_check.sh",
                        )
                    ],
                ),
            ),
            (
                {
                    "Scheduling": {
                        "SlurmQueues": [
                            {
                                "Name": "q1",
                                "HealthChecks": {"Gpu": {"Enabled": True}},
                                "ComputeResources": [
                                    {
                                        "Name": "c1",
                                        "HealthChecks": {"Gpu": {"Enabled": False}},
                                    }
                                ],
                            },
                        ]
                    }
                },
                "/my/path/for/checks",
                {
                    "cluster_configuration": "mocked",
                    "node_type": "ComputeFleet",
                    "queue_name": "q1",
                    "compute_resource_name": "c1",
                },
                HealthCheckConfig(
                    node_type="ComputeFleet",
                    queue_name="q1",
                    compute_resource_name="c1",
                    health_checks=[
                        HealthCheckDefinition(
                            name="Gpu",
                            is_managed=True,
                            is_enabled=False,
                            check_path="/my/path/for/checks/gpu_health_check.sh",
                        )
                    ],
                ),
            ),
            (
                {
                    "Scheduling": {
                        "SlurmQueues": [
                            {
                                "Name": "q1",
                                "HealthChecks": {"Gpu": {"Enabled": True}},
                                "ComputeResources": [
                                    {
                                        "Name": "c1",
                                        "HealthChecks": {"Gpu": {"Enabled": True}},
                                    }
                                ],
                            },
                        ]
                    }
                },
                "/my/path/for/checks",
                {
                    "cluster_configuration": "mocked",
                    "node_type": "ComputeFleet",
                    "queue_name": "q1",
                    "compute_resource_name": "c1",
                },
                HealthCheckConfig(
                    node_type="ComputeFleet",
                    queue_name="q1",
                    compute_resource_name="c1",
                    health_checks=[
                        HealthCheckDefinition(
                            name="Gpu",
                            is_managed=True,
                            is_enabled=True,
                            check_path="/my/path/for/checks/gpu_health_check.sh",
                        )
                    ],
                ),
            ),
            (
                {
                    "Scheduling": {
                        "SlurmQueues": [
                            {
                                "Name": "q1",
                                "HealthChecks": {"Gpu": {"Enabled": True}},
                                "ComputeResources": [
                                    {
                                        "Name": "c1",
                                        "HealthChecks": {"Gpu": {"Enabled": None}},
                                    },
                                    {
                                        "Name": "c2",
                                        "HealthChecks": {"Gpu": {"Enabled": True}},
                                    },
                                ],
                            },
                        ]
                    }
                },
                "/my/path/for/checks",
                {
                    "cluster_configuration": "mocked",
                    "node_type": "ComputeFleet",
                    "queue_name": "q1",
                    "compute_resource_name": "c1",
                },
                HealthCheckConfig(
                    node_type="ComputeFleet",
                    queue_name="q1",
                    compute_resource_name="c1",
                    health_checks=[
                        HealthCheckDefinition(
                            name="Gpu",
                            is_managed=True,
                            is_enabled=True,
                            check_path="/my/path/for/checks/gpu_health_check.sh",
                        )
                    ],
                ),
            ),
            (
                {
                    "Scheduling": {
                        "SlurmQueues": [
                            {
                                "Name": "q1",
                                "HealthChecks": {"Gpu": {"Enabled": True}},
                                "ComputeResources": [
                                    {
                                        "Name": "c1",
                                        "HealthChecks": {"Gpu": {"Enabled": False}},
                                    },
                                    {
                                        "Name": "c2",
                                        "HealthChecks": {"Gpu": {"Enabled": True}},
                                    },
                                ],
                            },
                        ]
                    }
                },
                "/my/path/for/checks",
                {
                    "cluster_configuration": "mocked",
                    "node_type": "ComputeFleet",
                    "queue_name": "q1",
                    "compute_resource_name": "c1",
                },
                HealthCheckConfig(
                    node_type="ComputeFleet",
                    queue_name="q1",
                    compute_resource_name="c1",
                    health_checks=[
                        HealthCheckDefinition(
                            name="Gpu",
                            is_managed=True,
                            is_enabled=False,
                            check_path="/my/path/for/checks/gpu_health_check.sh",
                        )
                    ],
                ),
            ),
        ],
    )
    def test_load_configuration(
        self, mocker, conf_file_content, health_check_dir_path, params, expected_health_check_conf
    ):
        """Test load_configuration method."""
        args = SimpleNamespace(**params)
        mocker.patch(
            "health_check_manager.HealthCheckConfigLoader._load_cluster_config", return_value=conf_file_content
        )
        health_check_manager_config = mocker.Mock(spec=HealthCheckManagerConfig)
        health_check_manager_config.managed_health_check_dir = health_check_dir_path

        health_check_conf = HealthCheckConfigLoader().load_configuration(health_check_manager_config, args)
        assert_that(expected_health_check_conf).is_equal_to(health_check_conf)

    @pytest.mark.parametrize(
        ("config_file", "expected_queue_name"),
        [
            (
                "config.yaml",
                "q1",
            ),
        ],
    )
    def test_load_cluster_config(self, test_datadir, config_file, expected_queue_name):
        """Test _load_cluster_config method."""
        cluster_config = HealthCheckConfigLoader()._load_cluster_config(test_datadir / config_file)
        assert_that(cluster_config["Scheduling"]["SlurmQueues"][0]["Name"]).is_equal_to(expected_queue_name)


@pytest.mark.parametrize(
    ("health_check_conf", "expected_exit_code", "expect_execution", "expect_failure"),
    [
        (
            HealthCheckConfig(
                node_type="ComputeFleet",
                queue_name="q1",
                compute_resource_name="c1",
                health_checks=[
                    HealthCheckDefinition(
                        name="Gpu",
                        is_managed=True,
                        is_enabled=True,
                        check_path="success.sh",
                    )
                ],
            ),
            0,
            True,
            False,
        ),
        (
            HealthCheckConfig(
                node_type="ComputeFleet",
                queue_name="q1",
                compute_resource_name="c1",
                health_checks=[
                    HealthCheckDefinition(
                        name="Gpu",
                        is_managed=True,
                        is_enabled=False,
                        check_path="success.sh",
                    )
                ],
            ),
            0,
            False,
            False,
        ),
        (
            HealthCheckConfig(
                node_type="ComputeFleet",
                queue_name="q1",
                compute_resource_name="c1",
                health_checks=[
                    HealthCheckDefinition(
                        name="Gpu",
                        is_managed=True,
                        is_enabled=True,
                        check_path="failure.sh",
                    )
                ],
            ),
            125,
            True,
            False,
        ),
        (
            HealthCheckConfig(
                node_type="ComputeFleet",
                queue_name="q1",
                compute_resource_name="c1",
                health_checks=[
                    HealthCheckDefinition(
                        name="Gpu",
                        is_managed=True,
                        is_enabled=True,
                        check_path="non-executable.sh",
                    )
                ],
            ),
            0,
            False,
            True,
        ),
        (
            HealthCheckConfig(
                node_type="ComputeFleet",
                queue_name="q1",
                compute_resource_name="c1",
                health_checks=[
                    HealthCheckDefinition(
                        name="Gpu",
                        is_managed=True,
                        is_enabled=True,
                        check_path="not-found",
                    )
                ],
            ),
            0,
            False,
            True,
        ),
        (
            HealthCheckConfig(
                node_type="ComputeFleet",
                queue_name="q1",
                compute_resource_name="c1",
                health_checks=[
                    HealthCheckDefinition(
                        name="Gpu",
                        is_managed=True,
                        is_enabled=True,
                        check_path="success.sh",
                    ),
                    HealthCheckDefinition(
                        name="Another",
                        is_managed=True,
                        is_enabled=True,
                        check_path="failure.sh",
                    ),
                ],
            ),
            125,
            True,
            False,
        ),
        (
            HealthCheckConfig(
                node_type="ComputeFleet",
                queue_name="q1",
                compute_resource_name="c1",
                health_checks=[],
            ),
            0,
            False,
            False,
        ),
    ],
)
def test_execute_health_checks(
    mocker, health_check_conf, expected_exit_code, expect_execution, expect_failure, test_datadir, caplog
):
    """Test _execute_health_checks method."""
    args = SimpleNamespace(
        node_spec_file="/node_spec_file",
        job_id=1,
    )

    node_spec = {
        "region": "us-east-1",
        "cluster_name": "integ-tests-e95bxovykj8zskbz-develop",
        "scheduler": "slurm",
        "node_role": "ComputeFleet",
        "instance_id": "i-051079accf0e1e224",
        "compute": {
            "queue-name": "queue-1",
            "compute-resource": "compute-a",
            "name": "queue-1-st-compute-a-1",
            "node-type": "static",
            "instance-id": "i-051079accf0e1e224",
            "instance-type": "g5.xlarge",
            "availability-zone": "us-east-1c",
            "address": "192.168.99.195",
            "hostname": "ip-192-168-99-195.ec2.internal",
        },
    }

    caplog.set_level(logging.INFO)
    health_check_manager_config = mocker.Mock(spec=HealthCheckManagerConfig)
    health_check_manager_config.health_check_timeout = 100
    mocker.patch("health_check_manager.HealthCheckConfigLoader.load_configuration", return_value=health_check_conf)
    mocker.patch("event_utils._read_node_spec", return_value=node_spec)
    for health_check in health_check_conf.health_checks:
        health_check.check_path = str(test_datadir / health_check.check_path)
    exit_code = health_check_manager._execute_health_checks(health_check_manager_config, args)
    assert_that(exit_code).is_equal_to(expected_exit_code)
    if expect_execution:
        assert_that(caplog.text).contains("err to stderr")
        assert_that(caplog.text).contains("output to stdout")
    else:
        assert_that(caplog.text).does_not_contain("err to stderr")
        assert_that(caplog.text).does_not_contain("output to stdout")
    if expect_failure:
        assert_that(caplog.text).contains("Failure when executing Health Check")
    else:
        assert_that(caplog.text).does_not_contain("Failure when executing Health Check")
