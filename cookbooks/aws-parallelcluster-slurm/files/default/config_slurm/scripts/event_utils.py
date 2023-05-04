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
import sys
import traceback
from collections import ChainMap
from datetime import datetime, timezone
from typing import Callable, Dict, Iterable

logger = logging.getLogger(__name__)
logger = logging.LoggerAdapter(logger, {"job_id": ""})


class EventPublisher:
    """Class for generating structured log events for cluster."""

    def __init__(
        self,
        event_logger: any,
        cluster_name: str,
        node_role: str,
        component: str,
        instance_id: str,
        **kwargs: Dict[str, any],
    ):
        self.event_publisher = EventPublisher._make_event_publisher(
            event_logger=event_logger,
            cluster_name=cluster_name,
            node_role=node_role,
            component=component,
            instance_id=instance_id,
            **kwargs,
        )

    @property
    def publish_event(self):
        """Return event publisher to publish an event."""
        return self.event_publisher

    @staticmethod
    def current_time() -> datetime:
        """Return current time in UTC."""
        return datetime.now(timezone.utc)

    @staticmethod
    def timestamp() -> str:
        """Return ISO formatted UTC timestamp."""
        return EventPublisher.current_time().isoformat(timespec="milliseconds")

    @staticmethod
    def _make_event_publisher(
        event_logger: any,
        cluster_name: str,
        node_role: str,
        component: str,
        instance_id: str,
        **global_args: Dict[str, any],
    ) -> Callable:
        def event_publisher(
            event_level, event_type, event_message, timestamp: str = None, event_supplier: Iterable = None, **kwargs
        ):
            if event_logger.isEnabledFor(event_level):
                try:
                    now = timestamp if timestamp else EventPublisher.timestamp()
                    if not event_supplier:
                        event_supplier = (kwargs,)
                    for event in event_supplier:
                        default_properties = {
                            "datetime": now,
                            "version": 0,
                            "scheduler": "slurm",
                            "cluster-name": cluster_name,
                            "node-role": node_role,
                            "component": component,
                            "level": logging.getLevelName(event_level),
                            "instance-id": instance_id,
                            "event-type": event_type,
                            "message": event_message,
                            "detail": {},
                        }
                        event = ChainMap(event, kwargs, default_properties, global_args)
                        event_logger.log(event_level, "%s", json.dumps(dict(event)))
                except Exception as e:
                    extraction = traceback.extract_stack()
                    logger.error(
                        "Failed to publish event `%s`: %s\n%s\n%s",
                        event_type,
                        e,
                        "".join(traceback.format_exception(*sys.exc_info())),
                        "".join(traceback.format_list(extraction)),
                    )

        return event_publisher


def publish_health_check_result(
    event_publisher: EventPublisher,
    job_id: str,
    health_check_name: str,
    health_check_result: int,
    health_check_output: str,
):
    def detail_supplier():
        yield {
            "detail": {
                "job-id": job_id,
                "health-check-name": health_check_name,
                "health-check-result": health_check_result,
                "health-check-output": f"{health_check_output}".split("\n") if health_check_output else None,
            },
        }

    try:
        event_publisher.publish_event(
            datetime=event_publisher.timestamp(),
            event_level=logging.WARNING if health_check_result else logging.INFO,
            event_type="compute-node-health-check",
            event_message=f"Result of compute node health check {health_check_name}",
            event_supplier=detail_supplier(),
        )
    except Exception as err:
        logger.error("Exception while publishing event: %s", repr(err))


def publish_health_check_exception(
    event_publisher: EventPublisher,
    job_id: str,
    health_check_name: str,
    err: Exception,
):
    try:
        event_publisher.publish_event(
            datetime=event_publisher.timestamp(),
            event_level=logging.ERROR,
            event_type="compute-node-health-check-exception",
            event_message=f"Failure when executing health check {health_check_name}",
            detail={
                "job-id": job_id,
                "health-check-name": health_check_name,
                "error": repr(err),
            },
        )
    except Exception as e:
        logger.error("Exception while publishing event: %s", repr(e))


def get_node_spec_from_file(node_spec_file: str) -> Dict[str, any]:
    if node_spec_file:
        try:
            return _read_node_spec(node_spec_file)
        except Exception as e:
            logger.error("Failed to load node spec file: %s", e)
    return {
        "region": "error",
        "cluster_name": "error",
        "scheduler": "error",
        "node_role": "ComputeFleet",
        "instance_id": "error",
        "compute": {
            "queue-name": "error",
            "compute-resource": "error",
            "name": "error",
            "node-type": "error",
            "instance-id": "error",
            "instance-type": "error",
            "availability-zone": "error",
            "address": "error",
            "hostname": "error",
        },
    }


def _read_node_spec(node_spec_path: str) -> Dict[str, any]:
    with open(node_spec_path, "r", encoding="utf-8") as file:
        return json.load(file)
