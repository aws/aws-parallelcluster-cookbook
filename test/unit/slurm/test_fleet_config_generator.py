# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
from pcluster_fleet_config_generator import ConfigurationFieldNotFoundError, CriticalError, generate_fleet_config_file


@pytest.mark.parametrize(
    "cluster_config, expected_exception, expected_message",
    [
        ({}, CriticalError, "Unable to find key 'Scheduling' in the configuration file"),
        ({"Scheduling": {}}, CriticalError, "Unable to find key 'SlurmQueues' in the configuration file"),
        ({"Scheduling": {"SlurmQueues": []}}, None, None),
        (
            {"Scheduling": {"SlurmQueues": [{"ComputeResources": []}]}},
            CriticalError,
            "Unable to find key 'Name' in the configuration file",
        ),
        (
            {"Scheduling": {"SlurmQueues": [{"Name": "q1"}]}},
            CriticalError,
            "Unable to find key 'ComputeResources' in the configuration of queue: q1",
        ),
        (
            {"Scheduling": {"SlurmQueues": [{"Name": "q1", "CapacityType": "ONDEMAND"}]}},
            CriticalError,
            "Unable to find key 'ComputeResources' in the configuration of queue: q1",
        ),
        ({"Scheduling": {"SlurmQueues": [{"Name": "q1", "CapacityType": "SPOT", "ComputeResources": []}]}}, None, None),
        (
            {
                "Scheduling": {
                    "SlurmQueues": [{"Name": "q1", "CapacityType": "SPOT", "ComputeResources": [{"Instances": []}]}]
                }
            },
            CriticalError,
            "Unable to find key 'Name' in the configuration of queue: q1",
        ),
        (
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "ONDEMAND",
                            "ComputeResources": [{"Name": "cr1", "Instances": []}],
                            "Networking": {"SubnetIds": ["123"]},
                        }
                    ]
                }
            },
            ConfigurationFieldNotFoundError,
            "Instances or InstanceType field not found in queue: q1, compute resource: cr1 configuration",
        ),
        (
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "ONDEMAND",
                            "ComputeResources": [
                                {"Name": "cr1", "Instances": [{"InstanceType": "test"}]},
                                {"Name": "cr2", "InstanceType": "test"},
                            ],
                            "Networking": {"SubnetIds": ["123"]},
                        }
                    ]
                }
            },
            None,
            None,
        ),
        (
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "ONDEMAND",
                            "ComputeResources": [
                                {"Name": "cr1", "Instances": [{"InstanceType": "test"}, {"InstanceType": "test-2"}]},
                                {"Name": "cr2", "InstanceType": "test"},
                            ],
                            "Networking": {"SubnetIds": ["123", "456", "789"]},
                        }
                    ]
                }
            },
            None,
            None,
        ),
        (
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "SPOT",
                            "ComputeResources": [
                                {
                                    "Name": "cr1",
                                    "Instances": [{"InstanceType": "test"}, {"InstanceType": "test-2"}],
                                    "SpotPrice": "10",
                                },
                                {"Name": "cr2", "InstanceType": "test", "SpotPrice": "10"},
                            ],
                            "Networking": {"SubnetIds": ["123", "456", "789"]},
                        }
                    ]
                }
            },
            None,
            None,
        ),
        (
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "SPOT",
                            "ComputeResources": [{"Name": "cr1", "Instances": [{"InstanceType": "test"}]}],
                            "Networking": {"SubnetIds": ["123"]},
                        }
                    ]
                }
            },
            CriticalError,
            "Unable to find key 'SpotPrice' in the configuration of queue: q1, compute resource: cr1",
        ),
        (
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "SPOT",
                            "ComputeResources": [
                                {"Name": "cr1", "Instances": [{"InstanceType": "test"}], "SpotPrice": 10}
                            ],
                            "Networking": {"SubnetIds": ["123"]},
                        }
                    ]
                }
            },
            None,
            None,
        ),
        (
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "SPOT",
                            "ComputeResources": [
                                {"Name": "cr1", "Instances": [{"InstanceType": "test"}], "SpotPrice": 10}
                            ],
                        }
                    ]
                }
            },
            CriticalError,
            "Unable to find key 'Networking' in the configuration of queue: q1, compute resource: cr1",
        ),
        (
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "SPOT",
                            "ComputeResources": [
                                {"Name": "cr1", "Instances": [{"InstanceType": "test"}], "SpotPrice": 10}
                            ],
                            "Networking": {},
                        }
                    ]
                }
            },
            CriticalError,
            "Unable to find key 'SubnetIds' in the configuration of queue: q1, compute resource: cr1",
        ),
        (
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "Name": "q1",
                            "CapacityType": "CAPACITY_BLOCK",
                            "ComputeResources": [
                                {
                                    "Name": "cr1",
                                    "Instances": [{"InstanceType": "test"}],
                                    "CapacityReservationTarget": {
                                        "CapacityReservationResourceGroupArn": "arn",
                                    },
                                },
                                {
                                    "Name": "cr2",
                                    "Instances": [{"InstanceType": "test"}],
                                    "CapacityReservationTarget": {
                                        "CapacityReservationId": "id",
                                    },
                                },
                            ],
                            "Networking": {"SubnetIds": ["123"]},
                        }
                    ]
                }
            },
            None,
            None,
        ),
    ],
)
def test_generate_fleet_config_file_error_cases(mocker, tmpdir, cluster_config, expected_exception, expected_message):
    mocker.patch("pcluster_fleet_config_generator._load_cluster_config", return_value=cluster_config)
    output_file = f"{tmpdir}/fleet-config.json"

    if expected_message:
        with pytest.raises(expected_exception, match=expected_message):
            generate_fleet_config_file(output_file, input_file="fake")
    else:
        generate_fleet_config_file(output_file, input_file="fake")


def test_generate_fleet_config_file(test_datadir, tmpdir):
    input_file = os.path.join(test_datadir, "sample_input.yaml")
    file_name = "fleet-config.json"
    output_file = f"{tmpdir}/{file_name}"

    generate_fleet_config_file(output_file, input_file)
    _assert_files_are_equal(tmpdir / file_name, test_datadir / "expected_outputs" / file_name)


def _assert_files_are_equal(file, expected_file):
    with open(file, "r", encoding="utf-8") as f, open(expected_file, "r", encoding="utf-8") as exp_f:
        expected_file_content = exp_f.read()
        expected_file_content = expected_file_content.replace("<DIR>", os.path.dirname(file))
        assert_that(f.read()).is_equal_to(expected_file_content)
