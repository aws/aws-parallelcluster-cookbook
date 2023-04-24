# Copyright 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
import json
import logging
from types import SimpleNamespace

import pytest
from assertpy import assert_that
from event_utils import EventPublisher, publish_health_check_exception, publish_health_check_result


@pytest.mark.parametrize(
    ("log_level", "result_code", "result_output", "expected_events"),
    [
        (
            logging.INFO,
            0,
            None,
            [
                {
                    "region": "us-east-1",
                    "scheduler": "slurm",
                    "compute": {
                        "queue-name": "queue",
                        "compute-resource": "compute",
                        "name": "queue-st-compute-1",
                        "node-type": "static",
                        "instance-id": "i-instance-id",
                        "instance-type": "g5.xlarge",
                        "availability-zone": "us-east-1c",
                        "address": "127.0.0.1",
                        "hostname": "ip-127-0-0-0.ec2.internal",
                    },
                    "datetime": "2023-04-19T01:57:56.410+00:00",
                    "version": 0,
                    "cluster-name": "cluster",
                    "node-role": "ComputeFleet",
                    "component": "test",
                    "level": "INFO",
                    "instance-id": "i-instance-id",
                    "event-type": "compute-node-health-check",
                    "message": "Result of compute node health check Gpu",
                    "detail": {
                        "job-id": 1,
                        "health-check-name": "Gpu",
                        "health-check-result": 0,
                        "health-check-output": None,
                    },
                }
            ],
        ),
        (
            logging.WARNING,
            0,
            "This message should not be present",
            [],
        ),
        (
            logging.WARNING,
            23,
            "Hello\nThis should\nbe an array\nof results",
            [
                {
                    "region": "us-east-1",
                    "scheduler": "slurm",
                    "compute": {
                        "queue-name": "queue",
                        "compute-resource": "compute",
                        "name": "queue-st-compute-1",
                        "node-type": "static",
                        "instance-id": "i-instance-id",
                        "instance-type": "g5.xlarge",
                        "availability-zone": "us-east-1c",
                        "address": "127.0.0.1",
                        "hostname": "ip-127-0-0-0.ec2.internal",
                    },
                    "datetime": "2023-04-19T01:57:29.511+00:00",
                    "version": 0,
                    "cluster-name": "cluster",
                    "node-role": "ComputeFleet",
                    "component": "test",
                    "level": "WARNING",
                    "instance-id": "i-instance-id",
                    "event-type": "compute-node-health-check",
                    "message": "Result of compute node health check Gpu",
                    "detail": {
                        "job-id": 1,
                        "health-check-name": "Gpu",
                        "health-check-result": 23,
                        "health-check-output": ["Hello", "This should", "be an array", "of results"],
                    },
                }
            ],
        ),
    ],
)
def test_publish_health_check_result(log_level, result_code, result_output, expected_events):
    def is_enabled_for(level):
        return level >= log_level

    def capture_log(event_level, format_string, json_string):
        assert_that(event_level).is_greater_than_or_equal_to(log_level)
        assert_that(format_string).is_not_none()
        captured_events.append(json.loads(json_string))

    node_spec = {
        "region": "us-east-1",
        "cluster_name": "cluster",
        "scheduler": "slurm",
        "node_role": "ComputeFleet",
        "instance_id": "i-instance-id",
        "compute": {
            "queue-name": "queue",
            "compute-resource": "compute",
            "name": "queue-st-compute-1",
            "node-type": "static",
            "instance-id": "i-instance-id",
            "instance-type": "g5.xlarge",
            "availability-zone": "us-east-1c",
            "address": "127.0.0.1",
            "hostname": "ip-127-0-0-0.ec2.internal",
        },
    }

    captured_events = []

    event_logger = SimpleNamespace(isEnabledFor=is_enabled_for, log=capture_log)

    event_publisher = EventPublisher(event_logger, component="test", **node_spec)

    publish_health_check_result(event_publisher, 1, "Gpu", result_code, result_output)

    assert_that(captured_events).is_length(len(expected_events))
    for actual, expected in zip(captured_events, expected_events):
        assert_that(actual).is_equal_to(expected, ignore="datetime")


@pytest.mark.parametrize(
    "expected_events",
    [
        [
            {
                "region": "us-east-1",
                "scheduler": "slurm",
                "compute": {
                    "queue-name": "queue",
                    "compute-resource": "compute",
                    "name": "queue-st-compute-1",
                    "node-type": "static",
                    "instance-id": "i-instance-id",
                    "instance-type": "g5.xlarge",
                    "availability-zone": "us-east-1c",
                    "address": "127.0.0.1",
                    "hostname": "ip-127-0-0-0.ec2.internal",
                },
                "datetime": "2023-04-19T01:57:06.030+00:00",
                "version": 0,
                "cluster-name": "cluster",
                "node-role": "ComputeFleet",
                "component": "test",
                "level": "ERROR",
                "instance-id": "i-instance-id",
                "event-type": "compute-node-health-check-exception",
                "message": "Failure when executing health check Gpu",
                "detail": {"job-id": 1, "health-check-name": "Gpu", "error": "Exception('What happened?')"},
            }
        ]
    ],
)
def test_publish_health_check_exception(expected_events):
    def is_enabled_for(*args):
        return True

    def capture_log(event_level, format_string, json_string):
        assert_that(event_level).is_greater_than_or_equal_to(logging.DEBUG)
        assert_that(format_string).is_not_none()
        captured_events.append(json.loads(json_string))

    node_spec = {
        "region": "us-east-1",
        "cluster_name": "cluster",
        "scheduler": "slurm",
        "node_role": "ComputeFleet",
        "instance_id": "i-instance-id",
        "compute": {
            "queue-name": "queue",
            "compute-resource": "compute",
            "name": "queue-st-compute-1",
            "node-type": "static",
            "instance-id": "i-instance-id",
            "instance-type": "g5.xlarge",
            "availability-zone": "us-east-1c",
            "address": "127.0.0.1",
            "hostname": "ip-127-0-0-0.ec2.internal",
        },
    }

    captured_events = []

    event_logger = SimpleNamespace(isEnabledFor=is_enabled_for, log=capture_log)

    event_publisher = EventPublisher(event_logger, component="test", **node_spec)

    publish_health_check_exception(event_publisher, 1, "Gpu", Exception("What happened?"))

    assert_that(captured_events).is_length(len(expected_events))
    for actual, expected in zip(captured_events, expected_events):
        assert_that(actual).is_equal_to(expected, ignore="datetime")


def test_exception_gets_swallowed():
    def is_enabled_for(*args):
        return True

    def raise_it(*args):
        nonlocal called
        called = True
        raise ValueError("Hello")

    called = False

    event_logger = SimpleNamespace(isEnabledFor=is_enabled_for, log=raise_it)
    event_publisher = EventPublisher(event_logger, "cluster", "ComputeFleet", "test", "id-instance")

    event_publisher.publish_event(event_level=logging.INFO, event_type="event-type", event_message="Message", detail={})

    assert_that(called).is_true()
