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

from unittest.mock import patch

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
            "MaxResults": 500,
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
    "compute_nodes, ddb_records, expected_error",
    [
        pytest.param(
            [],
            {},
            None,
            id="Create request with no compute nodes",
        ),
        pytest.param(
            ["i-123456789"],
            {},
            "Check failed due to the following erroneous records:\n"
            "  * missing records (1): ['i-123456789']\n"
            "  * incomplete records (0): []\n"
            "  * wrong records (0): []",
            id="Create request with missing DDB records",
        ),
        pytest.param(
            ["i-123456789"],
            {"i-123456789": {"UNEXPECTED_KEY": {"S": "UNEXPECTED_KEY_VALUE"}}},
            "Check failed due to the following erroneous records:\n"
            "  * missing records (0): []\n"
            "  * incomplete records (1): ['i-123456789']\n"
            "  * wrong records (0): []",
            id="Create request with malformed DDB records",
        ),
        pytest.param(
            ["i-123456789"],
            {"i-123456789": {"cluster_config_version": {"S": "WRONG_CLUSTER_CONFIG_VERSION"}}},
            "Check failed due to the following erroneous records:\n"
            "  * missing records (0): []\n"
            "  * incomplete records (0): []\n"
            "  * wrong records (1): [('i-123456789', 'WRONG_CLUSTER_CONFIG_VERSION')]",
            id="Create request with wrong cluster config version",
        ),
        pytest.param(
            ["i-123456789"],
            {"i-123456789": {"cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"}}},
            None,
            id="Create request with correct cluster config version",
        ),
    ],
)
def test_check_cluster_ready(boto3_stubber, compute_nodes, ddb_records, expected_error):
    boto3_stubber("ec2", [_mocked_request_describe_instances("CLUSTER_NAME", ["Compute"], compute_nodes)])

    boto3_stubber(
        "dynamodb", [_mocked_request_batch_get_items("TABLE_NAME", compute_nodes, ddb_records)] if compute_nodes else []
    )

    if expected_error is not None:
        with pytest.raises(CheckFailedError) as exc:
            check_cluster_ready("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION")
        assert_that(str(exc.value)).is_equal_to(expected_error)
    else:
        check_cluster_ready("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION")
