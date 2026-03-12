# Copyright 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with
#  the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

from unittest.mock import patch, mock_open

import pytest
from assertpy import assert_that
from common.exceptions import CheckFailedError
from utils import MockedBoto3Request, do_nothing_decorator

# This patching must be executed before the import of the module check_cluster_ready
# otherwise the module would be loaded with the original decorators.
# As a consequence, we need to suppress the linter rule E402 on every import below.
patch("retrying.retry", do_nothing_decorator).start()
patch("click.command", do_nothing_decorator).start()
patch("click.option", do_nothing_decorator).start()

from check_cluster_ready import check_cluster_ready  # noqa: E402


@pytest.fixture()
def boto3_stubber_path():
    return "common.aws.boto3"


def _mocked_request_describe_instances(cluster_name: str, node_types: [str], compute_nodes: [str]):
    return MockedBoto3Request(
        method="describe_instances",
        response={"Reservations": [{"Instances": [{"InstanceId": instance_id} for instance_id in compute_nodes]}]},
        expected_params={
            "Filters": [
                {"Name": "tag:parallelcluster:cluster-name", "Values": [cluster_name]},
                {"Name": "tag:parallelcluster:node-type", "Values": node_types},
                {"Name": "instance-state-name", "Values": ["running"]},
            ],
            "MaxResults": 100,
        },
        generate_error=False,
        error_code=None,
    )


def _mocked_request_batch_get_items(table_name: str, compute_nodes: [str], ddb_records: {}):
    keys = [{"Id": {"S": f"CLUSTER_CONFIG.{instance_id}"}} for instance_id in compute_nodes]
    returned_items = [
        {"Id": {"S": f"CLUSTER_CONFIG.{instance_id}"}, "Data": {"M": ddb_records[instance_id]}}
        for instance_id in ddb_records
    ]
    return MockedBoto3Request(
        method="batch_get_item",
        response={"Responses": {table_name: returned_items}},
        expected_params={
            "RequestItems": {
                table_name: {
                    "Keys": keys,
                },
            },
        },
        generate_error=False,
        error_code=None,
    )


@pytest.mark.parametrize(
    "compute_nodes, login_nodes, ddb_records, expected_error",
    [
        pytest.param(
            [],
            [],
            {},
            None,
            id="Check with no compute or login nodes",
        ),
        pytest.param(
            ["i-cmp123456789"],
            ["i-lgn123456789"],
            {},
            None,
            id="Check with missing DDB records",
        ),
        pytest.param(
            ["i-cmp123456789"],
            ["i-lgn123456789"],
            {
                "i-cmp123456789": {"UNEXPECTED_KEY_A": {"S": "UNEXPECTED_KEY_VALUE_A"}},
                "i-lgn123456789": {"UNEXPECTED_KEY_B": {"S": "UNEXPECTED_KEY_VALUE_B"}},
            },
            "Check failed due to the following erroneous records (missing records are not counted for the failure):\n"
            "  * missing records (0): []\n"
            "  * incomplete records (2): ['i-cmp123456789', 'i-lgn123456789']\n"
            "  * wrong records (0): []",
            id="Check with malformed DDB records",
        ),
        pytest.param(
            ["i-cmp123456789"],
            ["i-lgn123456789"],
            {
                "i-cmp123456789": {"cluster_config_version": {"S": "WRONG_CLUSTER_CONFIG_VERSION_A"}},
                "i-lgn123456789": {"cluster_config_version": {"S": "WRONG_CLUSTER_CONFIG_VERSION_B"}},
            },
            "Check failed due to the following erroneous records (missing records are not counted for the failure):\n"
            "  * missing records (0): []\n"
            "  * incomplete records (0): []\n"
            "  * wrong records (2): [('i-cmp123456789', 'WRONG_CLUSTER_CONFIG_VERSION_A'), "
            "('i-lgn123456789', 'WRONG_CLUSTER_CONFIG_VERSION_B')]",
            id="Check with wrong cluster config version",
        ),
        pytest.param(
            ["i-cmp1234567891", "i-cmp1234567892", "i-cmp1234567893", "i-cmp1234567894"],
            ["i-lgn1234567891", "i-lgn1234567892", "i-lgn1234567893", "i-lgn1234567894"],
            {
                "i-cmp1234567891": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
                "i-lgn1234567891": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
                "i-cmp1234567892": {"UNEXPECTED_KEY_A": {"S": "UNEXPECTED_KEY_VALUE_A"}},
                "i-lgn1234567892": {"UNEXPECTED_KEY_B": {"S": "UNEXPECTED_KEY_VALUE_B"}},
                "i-cmp1234567893": {"cluster_config_version": {"S": "WRONG_CLUSTER_CONFIG_VERSION_A"}},
                "i-lgn1234567893": {"cluster_config_version": {"S": "WRONG_CLUSTER_CONFIG_VERSION_B"}},
            },
            "Check failed due to the following erroneous records (missing records are not counted for the failure):\n"
            "  * missing records (2): ['i-cmp1234567894', 'i-lgn1234567894']\n"
            "  * incomplete records (2): ['i-cmp1234567892', 'i-lgn1234567892']\n"
            "  * wrong records (2): [('i-cmp1234567893', 'WRONG_CLUSTER_CONFIG_VERSION_A'), "
            "('i-lgn1234567893', 'WRONG_CLUSTER_CONFIG_VERSION_B')]",
            id="Check with mixed errors",
        ),
        pytest.param(
            ["i-cmp123456789"],
            ["i-lgn123456789"],
            {
                "i-cmp123456789": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
                "i-lgn123456789": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
            },
            None,
            id="Check with correct cluster config version",
        ),
    ],
)
def test_check_cluster_ready(boto3_stubber, compute_nodes, login_nodes, ddb_records, expected_error):
    all_nodes = compute_nodes + login_nodes

    boto3_stubber("ec2", [_mocked_request_describe_instances("CLUSTER_NAME", ["Compute", "LoginNode"], all_nodes)])

    boto3_stubber(
        "dynamodb", [_mocked_request_batch_get_items("TABLE_NAME", all_nodes, ddb_records)] if all_nodes else []
    )

    if expected_error is not None:
        with pytest.raises(CheckFailedError) as exc:
            check_cluster_ready("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION")
        assert_that(str(exc.value)).is_equal_to(expected_error)
    else:
        check_cluster_ready("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION")


def _mocked_request_describe_instances_with_queue(
    cluster_name: str, node_type: str, queue_names: [str], instance_ids: [str]
):
    """Mock EC2 describe_instances with optional queue filter."""
    filters = [
        {"Name": "tag:parallelcluster:cluster-name", "Values": [cluster_name]},
        {"Name": "tag:parallelcluster:node-type", "Values": [node_type]},
    ]
    if queue_names:
        filters.append({"Name": "tag:parallelcluster:queue-name", "Values": queue_names})
    filters.append({"Name": "instance-state-name", "Values": ["running"]})

    return MockedBoto3Request(
        method="describe_instances",
        response={"Reservations": [{"Instances": [{"InstanceId": iid} for iid in instance_ids]}]},
        expected_params={"Filters": filters, "MaxResults": 100},
        generate_error=False,
        error_code=None,
    )


@patch("check_cluster_ready.json.load")
@patch("check_cluster_ready.os.path.exists")
@patch("builtins.open", new_callable=mock_open)
def test_queue_filtering_single_modified(mock_file, mock_exists, mock_json_load, boto3_stubber):
    """Test that only nodes in modified queue are checked."""
    # Setup: change-set indicates queue1 was modified
    change_set = {
        "changeSet": [
            {"parameter": "Scheduling.SlurmQueues[queue1].ComputeResources[0].InstanceType", "requestedValue": "c5.xlarge"}
        ]
    }
    mock_exists.return_value = True
    mock_json_load.return_value = change_set

    compute_nodes_queue1 = ["i-queue1-node1", "i-queue1-node2"]
    login_nodes = ["i-login1"]
    ddb_records = {
        "i-queue1-node1": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
        "i-queue1-node2": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
        "i-login1": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
    }

    # Mock EC2: only queue1 compute nodes and login nodes should be queried
    boto3_stubber(
        "ec2",
        [
            _mocked_request_describe_instances_with_queue("CLUSTER_NAME", "Compute", ["queue1"], compute_nodes_queue1),
            _mocked_request_describe_instances_with_queue("CLUSTER_NAME", "LoginNode", None, login_nodes),
        ],
    )

    boto3_stubber("dynamodb", [
        _mocked_request_batch_get_items("TABLE_NAME", compute_nodes_queue1, ddb_records),
        _mocked_request_batch_get_items("TABLE_NAME", login_nodes, ddb_records),
    ])

    from check_cluster_ready import check_deployed_config_version
    check_deployed_config_version("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", "/fake/shared")


@patch("check_cluster_ready.json.load")
@patch("check_cluster_ready.os.path.exists")
@patch("builtins.open", new_callable=mock_open)
def test_queue_addition_new_queue(mock_file, mock_exists, mock_json_load, boto3_stubber):
    """Test adding a new queue with no nodes yet."""
    change_set = {
        "changeSet": [
            {"parameter": "Scheduling.SlurmQueues[new-queue].ComputeResources[0].InstanceType", "requestedValue": "c5.xlarge"}
        ]
    }
    mock_exists.return_value = True
    mock_json_load.return_value = change_set

    # No compute nodes in new queue yet, but login nodes exist
    login_nodes = ["i-login1"]
    ddb_records = {"i-login1": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}}}

    boto3_stubber(
        "ec2",
        [
            _mocked_request_describe_instances_with_queue("CLUSTER_NAME", "Compute", ["new-queue"], []),
            _mocked_request_describe_instances_with_queue("CLUSTER_NAME", "LoginNode", None, login_nodes),
        ],
    )

    boto3_stubber("dynamodb", [_mocked_request_batch_get_items("TABLE_NAME", login_nodes, ddb_records)])

    from check_cluster_ready import check_deployed_config_version
    check_deployed_config_version("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", "/fake/shared")


@patch("check_cluster_ready.os.path.exists")
def test_no_change_set_fallback(mock_exists, boto3_stubber):
    """Test fallback to checking all nodes when change-set.json is missing."""
    mock_exists.return_value = False  # change-set.json doesn't exist

    all_nodes = ["i-compute1", "i-compute2", "i-login1"]
    ddb_records = {
        "i-compute1": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
        "i-compute2": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
        "i-login1": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
    }

    # Should check all Compute + LoginNode without queue filter
    boto3_stubber("ec2", [_mocked_request_describe_instances("CLUSTER_NAME", ["Compute", "LoginNode"], all_nodes)])
    boto3_stubber("dynamodb", [_mocked_request_batch_get_items("TABLE_NAME", all_nodes, ddb_records)])

    from check_cluster_ready import check_deployed_config_version
    check_deployed_config_version("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", "/fake/shared")


@patch("check_cluster_ready.json.load")
@patch("check_cluster_ready.os.path.exists")
@patch("builtins.open", new_callable=mock_open)
def test_malformed_change_set_fallback(mock_file, mock_exists, mock_json_load, boto3_stubber):
    """Test fallback when change-set.json is malformed."""
    mock_exists.return_value = True
    mock_json_load.side_effect = ValueError("Invalid JSON")  # Simulate JSON parse error

    all_nodes = ["i-compute1", "i-login1"]
    ddb_records = {
        "i-compute1": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
        "i-login1": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
    }

    # Should fallback to checking all nodes
    boto3_stubber("ec2", [_mocked_request_describe_instances("CLUSTER_NAME", ["Compute", "LoginNode"], all_nodes)])
    boto3_stubber("dynamodb", [_mocked_request_batch_get_items("TABLE_NAME", all_nodes, ddb_records)])

    from check_cluster_ready import check_deployed_config_version
    check_deployed_config_version("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", "/fake/shared")


@patch("check_cluster_ready.json.load")
@patch("check_cluster_ready.os.path.exists")
@patch("builtins.open", new_callable=mock_open)
def test_login_nodes_always_checked(mock_file, mock_exists, mock_json_load, boto3_stubber):
    """Test that LoginNode is always checked separately from queues."""
    change_set = {
        "changeSet": [
            {"parameter": "Scheduling.SlurmQueues[queue1].ComputeResources[0].MaxCount", "requestedValue": "10"}
        ]
    }
    mock_exists.return_value = True
    mock_json_load.return_value = change_set

    compute_nodes = ["i-queue1-compute1"]
    login_nodes = ["i-login1", "i-login2"]
    ddb_records = {
        "i-queue1-compute1": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
        "i-login1": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
        "i-login2": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
    }

    boto3_stubber(
        "ec2",
        [
            _mocked_request_describe_instances_with_queue("CLUSTER_NAME", "Compute", ["queue1"], compute_nodes),
            _mocked_request_describe_instances_with_queue("CLUSTER_NAME", "LoginNode", None, login_nodes),
        ],
    )

    boto3_stubber("dynamodb", [
        _mocked_request_batch_get_items("TABLE_NAME", compute_nodes, ddb_records),
        _mocked_request_batch_get_items("TABLE_NAME", login_nodes, ddb_records),
    ])

    from check_cluster_ready import check_deployed_config_version
    check_deployed_config_version("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", "/fake/shared")


@patch("check_cluster_ready.json.load")
@patch("check_cluster_ready.os.path.exists")
@patch("builtins.open", new_callable=mock_open)
def test_mixed_queue_changes(mock_file, mock_exists, mock_json_load, boto3_stubber):
    """Test multiple queues modified simultaneously."""
    change_set = {
        "changeSet": [
            {"parameter": "Scheduling.SlurmQueues[queue1].ComputeResources[0].InstanceType", "requestedValue": "c5.xlarge"},
            {"parameter": "Scheduling.SlurmQueues[queue2].ComputeResources[0].MaxCount", "requestedValue": "5"},
        ]
    }
    mock_exists.return_value = True
    mock_json_load.return_value = change_set

    # Nodes in both queues should be checked
    compute_nodes_queue1 = ["i-q1-node1"]
    compute_nodes_queue2 = ["i-q2-node1", "i-q2-node2"]
    login_nodes = ["i-login1"]

    ddb_records = {
        "i-q1-node1": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
        "i-q2-node1": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
        "i-q2-node2": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
        "i-login1": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}},
    }

    # Note: EC2 filter will include both queues in Values list
    boto3_stubber(
        "ec2",
        [
            MockedBoto3Request(
                method="describe_instances",
                response={"Reservations": [
                    {"Instances": [{"InstanceId": iid} for iid in compute_nodes_queue1 + compute_nodes_queue2]}
                ]},
                expected_params={
                    "Filters": [
                        {"Name": "tag:parallelcluster:cluster-name", "Values": ["CLUSTER_NAME"]},
                        {"Name": "tag:parallelcluster:node-type", "Values": ["Compute"]},
                        {"Name": "tag:parallelcluster:queue-name", "Values": ["queue1", "queue2"]},
                        {"Name": "instance-state-name", "Values": ["running"]},
                    ],
                    "MaxResults": 100,
                },
                generate_error=False,
                error_code=None,
            ),
            _mocked_request_describe_instances_with_queue("CLUSTER_NAME", "LoginNode", None, login_nodes),
        ],
    )

    boto3_stubber("dynamodb", [
        _mocked_request_batch_get_items("TABLE_NAME", compute_nodes_queue1 + compute_nodes_queue2, ddb_records),
        _mocked_request_batch_get_items("TABLE_NAME", login_nodes, ddb_records),
    ])

    from check_cluster_ready import check_deployed_config_version
    check_deployed_config_version("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", "/fake/shared")
