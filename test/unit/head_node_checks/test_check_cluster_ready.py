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

from datetime import datetime, timezone
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

from check_cluster_ready import (  # noqa: E402
    _check_cluster_config_items,
    check_cluster_ready,
    completed_bootstrap_after,
)


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
            "Check failed due to the following erroneous records (missing records and wrong records tolerated, "
            "bootstrapped after cut-off time (None) are not counted for the failure):\n"
            "  * missing records (0): []\n"
            "  * incomplete records (2): ['i-cmp123456789', 'i-lgn123456789']\n"
            "  * wrong records (0): []\n"
            "  * wrong records tolerated, bootstrapped after cut-off time (None) (0): []",
            id="Check with malformed DDB records",
        ),
        pytest.param(
            ["i-cmp123456789"],
            ["i-lgn123456789"],
            {
                "i-cmp123456789": {"cluster_config_version": {"S": "WRONG_CLUSTER_CONFIG_VERSION_A"}},
                "i-lgn123456789": {"cluster_config_version": {"S": "WRONG_CLUSTER_CONFIG_VERSION_B"}},
            },
            "Check failed due to the following erroneous records (missing records and wrong records tolerated, "
            "bootstrapped after cut-off time (None) are not counted for the failure):\n"
            "  * missing records (0): []\n"
            "  * incomplete records (0): []\n"
            "  * wrong records (2): [('i-cmp123456789', 'WRONG_CLUSTER_CONFIG_VERSION_A'), "
            "('i-lgn123456789', 'WRONG_CLUSTER_CONFIG_VERSION_B')]\n"
            "  * wrong records tolerated, bootstrapped after cut-off time (None) (0): []",
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
            "Check failed due to the following erroneous records (missing records and wrong records tolerated, b"
            "ootstrapped after cut-off time (None) are not counted for the failure):\n"
            "  * missing records (2): ['i-cmp1234567894', 'i-lgn1234567894']\n"
            "  * incomplete records (2): ['i-cmp1234567892', 'i-lgn1234567892']\n"
            "  * wrong records (2): [('i-cmp1234567893', 'WRONG_CLUSTER_CONFIG_VERSION_A'), "
            "('i-lgn1234567893', 'WRONG_CLUSTER_CONFIG_VERSION_B')]\n"
            "  * wrong records tolerated, bootstrapped after cut-off time (None) (0): []",
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
            check_cluster_ready("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", None)
        assert_that(str(exc.value)).is_equal_to(expected_error)
    else:
        check_cluster_ready("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", None)


CUTOFF = datetime(2026, 3, 11, 11, 0, 0, tzinfo=timezone.utc)


@pytest.mark.parametrize(
    "data, cutoff, expected",
    [
        pytest.param(
            {"status": {"S": "DEPLOYED_BOOTSTRAP"}, "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"}},
            CUTOFF,
            True,
            id="Bootstrap status updated after cutoff",
        ),
        pytest.param(
            {"status": {"S": "DEPLOYED_BOOTSTRAP"}, "lastUpdateTime": {"S": "2026-03-11T10:00:00.000+00:00"}},
            CUTOFF,
            False,
            id="Bootstrap status updated before cutoff",
        ),
        pytest.param(
            {"status": {"S": "DEPLOYED_BOOTSTRAP"}, "lastUpdateTime": {"S": "2026-03-11T11:00:00.000+00:00"}},
            CUTOFF,
            True,
            id="Bootstrap status updated at exact cutoff",
        ),
        pytest.param(
            {"status": {"S": "DEPLOYED_UPDATE"}, "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"}},
            CUTOFF,
            False,
            id="Update status updated after cutoff is not tolerated",
        ),
        pytest.param(
            {"status": {"S": "DEPLOYED_BOOTSTRAP"}},
            CUTOFF,
            False,
            id="Bootstrap status with no lastUpdateTime",
        ),
        pytest.param(
            {"lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"}},
            CUTOFF,
            False,
            id="No status field",
        ),
        pytest.param(
            {},
            CUTOFF,
            False,
            id="Empty data",
        ),
        pytest.param(
            {"status": {"S": "DEPLOYED_BOOTSTRAP"}, "lastUpdateTime": {"S": "not-a-timestamp"}},
            CUTOFF,
            False,
            id="Bootstrap status with unparseable timestamp",
        ),
        pytest.param(
            {"status": {"S": "DEPLOYED_BOOTSTRAP"}, "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"}},
            None,
            False,
            id="No cutoff time provided",
        ),
    ],
)
def test_completed_bootstrap_after(data, cutoff, expected):
    assert_that(completed_bootstrap_after(data, cutoff)).is_equal_to(expected)


@pytest.mark.parametrize(
    "instance_ids, items, expected_missing, expected_incomplete, expected_wrong, expected_wrong_tolerated",
    [
        pytest.param(
            ["i-001"],
            [
                {
                    "Id": {"S": "CLUSTER_CONFIG.i-001"},
                    "Data": {
                        "M": {
                            "cluster_config_version": {"S": "OLD_VERSION"},
                            "status": {"S": "DEPLOYED_BOOTSTRAP"},
                            "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"},
                        }
                    },
                }
            ],
            [],
            [],
            [],
            ["i-001"],
            id="Wrong version bootstrap after cutoff is tolerated",
        ),
        pytest.param(
            ["i-001"],
            [
                {
                    "Id": {"S": "CLUSTER_CONFIG.i-001"},
                    "Data": {
                        "M": {
                            "cluster_config_version": {"S": "OLD_VERSION"},
                            "status": {"S": "DEPLOYED_BOOTSTRAP"},
                            "lastUpdateTime": {"S": "2026-03-11T10:00:00.000+00:00"},
                        }
                    },
                }
            ],
            [],
            [],
            [("i-001", "OLD_VERSION")],
            [],
            id="Wrong version bootstrap before cutoff is wrong",
        ),
        pytest.param(
            ["i-001"],
            [
                {
                    "Id": {"S": "CLUSTER_CONFIG.i-001"},
                    "Data": {
                        "M": {
                            "cluster_config_version": {"S": "OLD_VERSION"},
                            "status": {"S": "DEPLOYED_UPDATE"},
                            "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"},
                        }
                    },
                }
            ],
            [],
            [],
            [("i-001", "OLD_VERSION")],
            [],
            id="Wrong version update after cutoff is still wrong",
        ),
        pytest.param(
            ["i-001"],
            [
                {
                    "Id": {"S": "CLUSTER_CONFIG.i-001"},
                    "Data": {
                        "M": {
                            "cluster_config_version": {"S": "OLD_VERSION"},
                        }
                    },
                }
            ],
            [],
            [],
            [("i-001", "OLD_VERSION")],
            [],
            id="Wrong version no status or lastUpdateTime is wrong",
        ),
        pytest.param(
            ["i-correct", "i-wrong-old", "i-wrong-new", "i-wrong-update", "i-missing", "i-incomplete"],
            [
                {
                    "Id": {"S": "CLUSTER_CONFIG.i-correct"},
                    "Data": {
                        "M": {
                            "cluster_config_version": {"S": "EXPECTED_VERSION"},
                            "status": {"S": "DEPLOYED_UPDATE"},
                            "lastUpdateTime": {"S": "2026-03-11T10:00:00.000+00:00"},
                        }
                    },
                },
                {
                    "Id": {"S": "CLUSTER_CONFIG.i-wrong-old"},
                    "Data": {
                        "M": {
                            "cluster_config_version": {"S": "OLD_VERSION"},
                            "status": {"S": "DEPLOYED_BOOTSTRAP"},
                            "lastUpdateTime": {"S": "2026-03-11T10:00:00.000+00:00"},
                        }
                    },
                },
                {
                    "Id": {"S": "CLUSTER_CONFIG.i-wrong-new"},
                    "Data": {
                        "M": {
                            "cluster_config_version": {"S": "OLD_VERSION"},
                            "status": {"S": "DEPLOYED_BOOTSTRAP"},
                            "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"},
                        }
                    },
                },
                {
                    "Id": {"S": "CLUSTER_CONFIG.i-wrong-update"},
                    "Data": {
                        "M": {
                            "cluster_config_version": {"S": "OLD_VERSION"},
                            "status": {"S": "DEPLOYED_UPDATE"},
                            "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"},
                        }
                    },
                },
                {
                    "Id": {"S": "CLUSTER_CONFIG.i-incomplete"},
                    "Data": {
                        "M": {
                            "some_other_key": {"S": "value"},
                        }
                    },
                },
            ],
            ["i-missing"],
            ["i-incomplete"],
            [("i-wrong-old", "OLD_VERSION"), ("i-wrong-update", "OLD_VERSION")],
            ["i-wrong-new"],
            id="Mixed with cutoff",
        ),
    ],
)
def test_check_cluster_config_items_with_cutoff(
    instance_ids, items, expected_missing, expected_incomplete, expected_wrong, expected_wrong_tolerated
):
    missing, incomplete, wrong, wrong_tolerated = _check_cluster_config_items(
        instance_ids, items, "EXPECTED_VERSION", CUTOFF
    )
    assert_that(missing).is_equal_to(expected_missing)
    assert_that(incomplete).is_equal_to(expected_incomplete)
    assert_that(wrong).is_equal_to(expected_wrong)
    assert_that(wrong_tolerated).is_equal_to(expected_wrong_tolerated)


@pytest.mark.parametrize(
    "ddb_records, cutoff_time_str, should_fail",
    [
        pytest.param(
            {
                "i-001": {
                    "cluster_config_version": {"S": "OLD_VERSION"},
                    "status": {"S": "DEPLOYED_BOOTSTRAP"},
                    "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"},
                },
            },
            "2026-03-11T11:00:00.000+00:00",
            False,
            id="Wrong version bootstrap after cutoff passes",
        ),
        pytest.param(
            {
                "i-001": {
                    "cluster_config_version": {"S": "OLD_VERSION"},
                    "status": {"S": "DEPLOYED_BOOTSTRAP"},
                    "lastUpdateTime": {"S": "2026-03-11T10:00:00.000+00:00"},
                },
            },
            "2026-03-11T11:00:00.000+00:00",
            True,
            id="Wrong version bootstrap before cutoff fails",
        ),
        pytest.param(
            {
                "i-001": {
                    "cluster_config_version": {"S": "OLD_VERSION"},
                    "status": {"S": "DEPLOYED_UPDATE"},
                    "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"},
                },
            },
            "2026-03-11T11:00:00.000+00:00",
            True,
            id="Wrong version update after cutoff still fails",
        ),
        pytest.param(
            {
                "i-tolerated": {
                    "cluster_config_version": {"S": "OLD_VERSION"},
                    "status": {"S": "DEPLOYED_BOOTSTRAP"},
                    "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"},
                },
            },
            "2026-03-11T11:00:00.000+00:00",
            False,
            id="Only tolerated records passes with warning",
        ),
        pytest.param(
            {
                "i-wrong": {
                    "cluster_config_version": {"S": "OLD_VERSION"},
                    "status": {"S": "DEPLOYED_BOOTSTRAP"},
                    "lastUpdateTime": {"S": "2026-03-11T10:00:00.000+00:00"},
                },
                "i-tolerated": {
                    "cluster_config_version": {"S": "OLD_VERSION"},
                    "status": {"S": "DEPLOYED_BOOTSTRAP"},
                    "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"},
                },
            },
            "2026-03-11T11:00:00.000+00:00",
            True,
            id="Wrong + tolerated still fails",
        ),
        pytest.param(
            {
                "i-wrong-update": {
                    "cluster_config_version": {"S": "OLD_VERSION"},
                    "status": {"S": "DEPLOYED_UPDATE"},
                    "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"},
                },
                "i-tolerated": {
                    "cluster_config_version": {"S": "OLD_VERSION"},
                    "status": {"S": "DEPLOYED_BOOTSTRAP"},
                    "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"},
                },
            },
            "2026-03-11T11:00:00.000+00:00",
            True,
            id="Wrong update + tolerated still fails",
        ),
    ],
)
def test_check_cluster_ready_with_cutoff(boto3_stubber, ddb_records, cutoff_time_str, should_fail):
    nodes = list(ddb_records.keys())
    boto3_stubber("ec2", [_mocked_request_describe_instances("CLUSTER_NAME", ["Compute", "LoginNode"], nodes)])
    boto3_stubber("dynamodb", [_mocked_request_batch_get_items("TABLE_NAME", nodes, ddb_records)])

    if should_fail:
        with pytest.raises(CheckFailedError):
            check_cluster_ready("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", cutoff_time_str)
    else:
        check_cluster_ready("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", cutoff_time_str)


def test_check_cluster_ready_missing_and_tolerated_passes(boto3_stubber):
    """Missing + tolerated (no wrong) should pass with warnings."""
    all_nodes = ["i-missing", "i-tolerated"]
    ddb_records = {
        "i-tolerated": {
            "cluster_config_version": {"S": "OLD_VERSION"},
            "status": {"S": "DEPLOYED_BOOTSTRAP"},
            "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"},
        },
    }
    boto3_stubber("ec2", [_mocked_request_describe_instances("CLUSTER_NAME", ["Compute", "LoginNode"], all_nodes)])
    boto3_stubber("dynamodb", [_mocked_request_batch_get_items("TABLE_NAME", all_nodes, ddb_records)])

    # Should not raise
    check_cluster_ready(
        "CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", "2026-03-11T11:00:00.000+00:00"
    )


def test_check_cluster_ready_missing_and_wrong_fails(boto3_stubber):
    """Missing + wrong (no tolerated) should fail."""
    all_nodes = ["i-missing", "i-wrong"]
    ddb_records = {
        "i-wrong": {
            "cluster_config_version": {"S": "OLD_VERSION"},
            "status": {"S": "DEPLOYED_BOOTSTRAP"},
            "lastUpdateTime": {"S": "2026-03-11T10:00:00.000+00:00"},
        },
    }
    boto3_stubber("ec2", [_mocked_request_describe_instances("CLUSTER_NAME", ["Compute", "LoginNode"], all_nodes)])
    boto3_stubber("dynamodb", [_mocked_request_batch_get_items("TABLE_NAME", all_nodes, ddb_records)])

    with pytest.raises(CheckFailedError):
        check_cluster_ready(
            "CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", "2026-03-11T11:00:00.000+00:00"
        )


def test_check_cluster_ready_missing_wrong_and_tolerated_fails(boto3_stubber):
    """Missing + wrong + tolerated should fail."""
    all_nodes = ["i-missing", "i-wrong", "i-tolerated"]
    ddb_records = {
        "i-wrong": {
            "cluster_config_version": {"S": "OLD_VERSION"},
            "status": {"S": "DEPLOYED_BOOTSTRAP"},
            "lastUpdateTime": {"S": "2026-03-11T10:00:00.000+00:00"},
        },
        "i-tolerated": {
            "cluster_config_version": {"S": "OLD_VERSION"},
            "status": {"S": "DEPLOYED_BOOTSTRAP"},
            "lastUpdateTime": {"S": "2026-03-11T12:00:00.000+00:00"},
        },
    }
    boto3_stubber("ec2", [_mocked_request_describe_instances("CLUSTER_NAME", ["Compute", "LoginNode"], all_nodes)])
    boto3_stubber("dynamodb", [_mocked_request_batch_get_items("TABLE_NAME", all_nodes, ddb_records)])

    with pytest.raises(CheckFailedError):
        check_cluster_ready(
            "CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", "2026-03-11T11:00:00.000+00:00"
        )


def test_check_cluster_config_items_empty_instance_ids():
    """Empty instance_ids should return all empty lists (early return with warning)."""
    missing, incomplete, wrong, wrong_tolerated = _check_cluster_config_items([], [], "EXPECTED_VERSION", CUTOFF)
    assert_that(missing).is_equal_to([])
    assert_that(incomplete).is_equal_to([])
    assert_that(wrong).is_equal_to([])
    assert_that(wrong_tolerated).is_equal_to([])


def test_check_cluster_ready_unparseable_cutoff_time(boto3_stubber):
    """Unparseable cutoff-time should be ignored (treated as None) and check should pass."""
    ddb_records = {
        "i-001": {
            "cluster_config_version": {"S": "EXPECTED_CONFIG_VERSION"},
        },
    }
    nodes = list(ddb_records.keys())
    boto3_stubber("ec2", [_mocked_request_describe_instances("CLUSTER_NAME", ["Compute", "LoginNode"], nodes)])
    boto3_stubber("dynamodb", [_mocked_request_batch_get_items("TABLE_NAME", nodes, ddb_records)])

    # Should not raise; the bad cutoff-time is silently ignored
    check_cluster_ready("CLUSTER_NAME", "TABLE_NAME", "EXPECTED_CONFIG_VERSION", "REGION", "not-a-valid-timestamp")
