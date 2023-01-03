# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

import functools
import json
import logging
import os
import shlex

# A nosec comment is appended to the following line in order to disable the B404 check.
# In this file the input of the module subprocess is trusted.
import subprocess  # nosec B404
import time
from configparser import ConfigParser
from datetime import datetime, timezone
from enum import Enum
from logging.config import fileConfig

import boto3
from boto3.dynamodb.conditions import Attr
from botocore.config import Config

CONFIG_FILE_DIR = "/etc/parallelcluster"
LOOP_TIME = 60
log = logging.getLogger(__name__)


# Utils
def _seconds(sec):
    """Convert seconds to milliseconds."""
    return sec * 1000


def _minutes(min):
    """Convert minutes to seconds."""
    return min * 60


def _sleep_remaining_loop_time(total_loop_time, loop_start_time=None):
    end_time = datetime.now(tz=timezone.utc)
    if not loop_start_time:
        loop_start_time = end_time
    # Always convert the received loop_start_time to utc timezone. This is so that we never rely on the system local
    # time and risk to compare native datatime instances with localized ones
    loop_start_time = loop_start_time.astimezone(tz=timezone.utc)
    time_delta = (end_time - loop_start_time).total_seconds()
    if 0 <= time_delta < total_loop_time:
        time.sleep(total_loop_time - time_delta)


def log_exception(
    logger,
    action_desc,
    log_level=logging.ERROR,
    catch_exception=Exception,
    raise_on_error=True,
    exception_to_raise=None,
):
    def decorator_log_exception(function):
        @functools.wraps(function)
        def wrapper_log_expection(*args, **kwargs):  # pylint: disable=R1710
            try:
                return function(*args, **kwargs)
            except catch_exception as e:
                logger.log(log_level, "Failed when %s with exception %s", action_desc, e)
                if raise_on_error:
                    if exception_to_raise:
                        raise exception_to_raise
                    raise

        return wrapper_log_expection

    return decorator_log_exception


def _run_command(  # noqa: C901
    command,
    capture_output=False,
    log_error=True,
    env=None,
    timeout=None,
    raise_on_error=True,
):
    """Execute shell command."""
    if isinstance(command, str):
        command = shlex.split(command)
    log_command = command if isinstance(command, str) else " ".join(str(arg) for arg in command)
    log.info("Executing command: %s", log_command)
    try:
        result = subprocess.run(  # nosec - trusted input
            command,
            capture_output=capture_output,
            universal_newlines=True,
            encoding="utf-8",
            env=env,
            timeout=timeout,
            check=False,
        )
        result.check_returncode()
    except subprocess.CalledProcessError:
        if log_error:
            log.error(
                "Command %s failed",
                log_command,
            )
        if raise_on_error:
            raise
    except subprocess.TimeoutExpired:
        if log_error:
            log.error("Command %s timed out after %s sec", log_command, timeout)
        if raise_on_error:
            raise

    return result


def _write_json_to_file(filename, json_data):
    """Write json to file."""
    with open(filename, "w", encoding="utf-8") as file:
        file.write(json.dumps(json_data))


class ComputeFleetStatus(Enum):
    """Represents the status of the cluster compute fleet."""

    STOPPED = "STOPPED"  # Fleet is stopped, partitions are inactive.
    RUNNING = "RUNNING"  # Fleet is running, partitions are active.
    STOPPING = "STOPPING"  # clusterstatusmgtd is handling the stop request.
    STARTING = "STARTING"  # clusterstatusmgtd is handling the start request.
    STOP_REQUESTED = "STOP_REQUESTED"  # A request to stop the fleet has been submitted.
    START_REQUESTED = "START_REQUESTED"  # A request to start the fleet has been submitted.
    # PROTECTED indicates that some partitions have consistent bootstrap failures. Affected partitions are inactive.
    PROTECTED = "PROTECTED"

    # cluster compute fleet mapping for status exposed to the update event handler
    EVENT_HANDLER_STATUS_MAPPING = {STOPPING: STOP_REQUESTED, STARTING: START_REQUESTED}
    UNKNOWN = "UNKNOWN"

    def __str__(self):  # noqa: D105
        return str(self.value)

    @staticmethod
    def _transform_compute_fleet_data(compute_fleet_data):
        try:
            compute_fleet_data[
                ComputeFleetStatusManager.COMPUTE_FLEET_STATUS_ATTRIBUTE
            ] = ComputeFleetStatus.EVENT_HANDLER_STATUS_MAPPING.value.get(
                compute_fleet_data.get(ComputeFleetStatusManager.COMPUTE_FLEET_STATUS_ATTRIBUTE),
                str(ComputeFleetStatus.UNKNOWN),
            )
            return compute_fleet_data
        except AttributeError as e:
            raise Exception(f"Unable to parse compute fleet status data: {e}")

    @staticmethod
    def is_start_in_progress(status):  # noqa: D102
        return status in {ComputeFleetStatus.START_REQUESTED, ComputeFleetStatus.STARTING}

    @staticmethod
    def is_stop_in_progress(status):  # noqa: D102
        return status in {ComputeFleetStatus.STOP_REQUESTED, ComputeFleetStatus.STOPPING}

    @staticmethod
    def is_protected_status(status):  # noqa: D102
        return status == ComputeFleetStatus.PROTECTED


class ComputeFleetStatusManager:
    """
    Manages the compute fleet status store into the DynamoDB table.

    The value stored in the table is a json in the following form
    {
      "status": "STOPPING",
      "lastStatusUpdatedTime": "2021-12-21 18:12:07.485674+00:00",
      "queues": {
        "queue_name1": {
            "status": "RUNNING",
            "lastStatusUpdatedTime": "2021-12-21 18:10:02.485674+00:00",
        }
      }
    }
    """

    DB_KEY = "COMPUTE_FLEET"
    DB_DATA = "Data"

    COMPUTE_FLEET_STATUS_ATTRIBUTE = "status"
    COMPUTE_FLEET_LAST_UPDATED_TIME_ATTRIBUTE = "lastStatusUpdatedTime"

    QUEUES_ATTRIBUTE = "queues"
    QUEUE_STATUS_ATTRIBUTE = "status"
    QUEUE_LAST_UPDATED_TIME_ATTRIBUTE = "lastStatusUpdatedTime"

    class ConditionalStatusUpdateFailedError(Exception):
        """Raised when there is a failure in updating the status due to a change occurred after retrieving its value."""

        pass

    def __init__(self, table_name, boto3_config, region):
        self._ddb_resource = boto3.resource("dynamodb", region_name=region, config=boto3_config)
        self._table = self._ddb_resource.Table(table_name)

    def get_status(self):  # noqa: D102
        compute_fleet_item = self._table.get_item(
            ConsistentRead=True,
            Key={"Id": self.DB_KEY},
        )
        if not compute_fleet_item or "Item" not in compute_fleet_item:
            raise Exception("COMPUTE_FLEET data not found in db table")

        log.debug("Found COMPUTE_FLEET data (%s)", compute_fleet_item)
        return compute_fleet_item["Item"].get(self.DB_DATA)

    def update_status(self, current_status, next_status):  # noqa: D102
        try:
            updated_attributes = self._table.update_item(
                Key={"Id": self.DB_KEY},
                UpdateExpression="set #dt.#st=:s, #dt.#lut=:t",
                ExpressionAttributeNames={
                    "#dt": self.DB_DATA,
                    "#st": self.COMPUTE_FLEET_STATUS_ATTRIBUTE,
                    "#lut": self.COMPUTE_FLEET_LAST_UPDATED_TIME_ATTRIBUTE,
                },
                ExpressionAttributeValues={
                    ":s": str(next_status),
                    ":t": str(datetime.now(tz=timezone.utc)),
                },
                ConditionExpression=Attr(f"{self.DB_DATA}.{self.COMPUTE_FLEET_STATUS_ATTRIBUTE}").eq(
                    str(current_status)
                ),
                ReturnValues="ALL_NEW",
            )

            return updated_attributes.get("Attributes").get(f"{self.DB_DATA}")
        except self._ddb_resource.meta.client.exceptions.ConditionalCheckFailedException as e:
            raise ComputeFleetStatusManager.ConditionalStatusUpdateFailedError(e)


class ClusterstatusmgtdConfig:
    """Represents the cluster status management demon configuration."""

    DEFAULTS = {
        "max_retry": 5,
        "loop_time": LOOP_TIME,
        "proxy": "NONE",
        "logging_config": os.path.join(os.path.dirname(__file__), "clusterstatusmgtd_logging.conf"),
        "update_event_timeout_minutes": 15,
    }

    def __init__(self, config_file_path):
        self._get_config(config_file_path)

    def __repr__(self):  # noqa: D105
        attrs = ", ".join([f"{key}={repr(value)}" for key, value in self.__dict__.items()])
        return f"{self.__class__.__name__}({attrs})"

    def __eq__(self, other):  # noqa: D105
        if type(other) is type(self):
            return self._config == other._config
        return False

    def __ne__(self, other):  # noqa: D105
        return not self.__eq__(other)

    @log_exception(
        log, "reading cluster status manger configuration file", catch_exception=IOError, raise_on_error=True
    )
    def _get_config(self, config_file_path):
        """Get clusterstatusmgtd configuration."""
        log.info("Reading %s", config_file_path)
        self._config = ConfigParser()
        with open(config_file_path, "r", encoding="utf-8") as config_file:
            self._config.read_file(config_file)

        # Get config settings
        self._get_basic_config(self._config)

    def _get_basic_config(self, config):
        """Get basic config options."""
        self.region = config.get("clusterstatusmgtd", "region")
        self.cluster_name = config.get("clusterstatusmgtd", "cluster_name")
        self.dynamodb_table = config.get("clusterstatusmgtd", "dynamodb_table")
        self.computefleet_status_path = config.get("clusterstatusmgtd", "computefleet_status_path")
        self.logging_config = config.get(
            "clusterstatusmgtd", "logging_config", fallback=self.DEFAULTS.get("logging_config")
        )
        self.loop_time = config.getint("clusterstatusmgtd", "loop_time", fallback=self.DEFAULTS.get("loop_time"))
        self.update_event_timeout_minutes = config.getint(
            "clusterstatusmgtd",
            "update_event_timeout_minutes",
            fallback=self.DEFAULTS.get("update_event_timeout_minutes"),
        )

        # Configure boto3 to retry 1 times by default
        self._boto3_retry = config.getint("clusterstatusmgtd", "boto3_retry", fallback=self.DEFAULTS.get("max_retry"))
        self._boto3_config = {"retries": {"max_attempts": self._boto3_retry, "mode": "standard"}}
        # Configure proxy
        proxy = config.get("clusterstatusmgtd", "proxy", fallback=self.DEFAULTS.get("proxy"))
        if proxy != "NONE":
            self._boto3_config["proxies"] = {"https": proxy}
        self.boto3_config = Config(**self._boto3_config)


class ClusterStatusManager:
    """The cluster status manager."""

    def __init__(self, config):
        """Initialize ClusterStatusManager."""
        self._config = None
        self._current_time = None
        self._compute_fleet_status_manager = None
        self._compute_fleet_status = ComputeFleetStatus.RUNNING
        self._compute_fleet_data = {}
        self.set_config(config)

    def set_config(self, config):  # noqa: D102
        if self._config != config:
            log.info("Applying new clusterstatusmgtd config: %s", config)
            self._config = config
            self._compute_fleet_status_manager = self._initialize_compute_fleet_status_manager(config)

    @staticmethod
    def _initialize_compute_fleet_status_manager(config):
        return ComputeFleetStatusManager(
            table_name=config.dynamodb_table, boto3_config=config.boto3_config, region=config.region
        )

    def _get_compute_fleet_status(self, fallback=None):
        try:
            log.info("Getting compute fleet status")
            self._compute_fleet_data = self._compute_fleet_status_manager.get_status()

            return ComputeFleetStatus(
                self._compute_fleet_data.get(self._compute_fleet_status_manager.COMPUTE_FLEET_STATUS_ATTRIBUTE)
            )
        except Exception as e:
            log.error(
                "Failed when retrieving computefleet status from DynamoDB with error %s, using fallback value %s",
                e,
                fallback,
            )
            return fallback

    def _update_compute_fleet_status(self, new_status):
        log.info("Updating compute fleet status from %s to %s", self._compute_fleet_status, new_status)
        self._compute_fleet_data = self._compute_fleet_status_manager.update_status(
            current_status=self._compute_fleet_status, next_status=new_status
        )
        self._compute_fleet_status = new_status

    def _call_update_event(self):
        try:
            compute_fleet_data = ComputeFleetStatus._transform_compute_fleet_data(  # pylint: disable=W0212
                self._compute_fleet_data
            )
            _write_json_to_file(self._config.computefleet_status_path, compute_fleet_data)
        except Exception as e:
            log.error("Update event handler failed during fleet status translation: %s", e)
            raise

        cinc_log_file = "/var/log/chef-client.log"
        log.info("Calling update event handler, log can be found at %s", cinc_log_file)
        cmd = (
            "sudo cinc-client "
            "--local-mode "
            "--config /etc/chef/client.rb "
            "--log_level auto "
            f"--logfile {cinc_log_file} "
            "--force-formatter "
            "--no-color "
            "--chef-zero-port 8889 "
            "--json-attributes /etc/chef/dna.json "
            "--override-runlist aws-parallelcluster::update_computefleet_status"
        )
        try:
            _run_command(cmd, self._config.update_event_timeout_minutes)
        except Exception:
            log.error("Update event handler failed. Check log file %s", cinc_log_file)
            raise

    def _update_status(self, request_status, in_progress_status, final_status):
        if self._compute_fleet_status == request_status:
            self._update_compute_fleet_status(in_progress_status)

        self._call_update_event()
        if self._compute_fleet_status == in_progress_status:
            self._update_compute_fleet_status(final_status)

    @log_exception(log, "handling compute fleet status transitions", catch_exception=Exception, raise_on_error=False)
    def manage_cluster_status(self):
        """
        Manage cluster status.

        When running pcluster start/stop command the fleet status is set to START_REQUESTED/STOP_REQUESTED.
        The function fetches the current fleet status and performs the following transitions:
          - START_REQUESTED -> STARTING -> RUNNING
          - STOP_REQUESTED -> STOPPING -> STOPPED
        STARTING/STOPPING states are only used to communicate that the request is being processed by clusterstatusmgtd.
        On status STARTING|STOPPING, the update event handler baked by the recipe
        aws-parallelcluster::update_computefleet_status is called
        """
        self._current_time = datetime.now(tz=timezone.utc)
        self._compute_fleet_status = self._get_compute_fleet_status(fallback=self._compute_fleet_status)
        log.info("Current compute fleet status: %s", self._compute_fleet_status)
        try:
            if ComputeFleetStatus.is_stop_in_progress(self._compute_fleet_status):
                self._update_status(
                    ComputeFleetStatus.STOP_REQUESTED, ComputeFleetStatus.STOPPING, ComputeFleetStatus.STOPPED
                )
            elif ComputeFleetStatus.is_start_in_progress(self._compute_fleet_status):
                self._update_status(
                    ComputeFleetStatus.START_REQUESTED, ComputeFleetStatus.STARTING, ComputeFleetStatus.RUNNING
                )
        except ComputeFleetStatusManager.ConditionalStatusUpdateFailedError:
            log.warning(
                "Cluster status was updated while handling a transition from %s. "
                "Status transition will be retried at the next iteration",
                self._compute_fleet_status,
            )


def _run_clusterstatusmgtd(config_file):
    config = ClusterstatusmgtdConfig(config_file)
    cluster_status_manager = ClusterStatusManager(config=config)
    while True:
        # Get loop start time
        start_time = datetime.now(tz=timezone.utc)
        # Get program config
        try:
            config = ClusterstatusmgtdConfig(config_file)
            cluster_status_manager.set_config(config)
        except Exception as e:
            log.warning("Unable to reload daemon config from %s, using previous one.\nException: %s", config_file, e)
        # Configure root logger
        try:
            fileConfig(config.logging_config, disable_existing_loggers=False)
        except Exception as e:
            log.warning(
                "Unable to configure logging from %s, using default logging settings.\nException: %s",
                config.logging_config,
                e,
            )
        # Manage cluster
        cluster_status_manager.manage_cluster_status()
        _sleep_remaining_loop_time(config.loop_time, start_time)


def retry(delay):
    def decorator_retry(func):
        @functools.wraps(func)
        def wrapper_retry(*args, **kwargs):
            while True:
                try:
                    return func(*args, **kwargs)
                except Exception:
                    time.sleep(delay)

        return wrapper_retry

    return decorator_retry


@retry(LOOP_TIME)
def main():
    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s - [%(module)s:%(funcName)s] - %(levelname)s - %(message)s"
    )
    log.info("Clusterstatusmgtd Startup")
    try:
        clusterstatusmgtd_config_file = os.environ.get(
            "CONFIG_FILE", os.path.join(CONFIG_FILE_DIR, "clusterstatusmgtd.conf")
        )
        _run_clusterstatusmgtd(clusterstatusmgtd_config_file)
    except Exception as e:
        log.exception("An unexpected error occurred: %s.\nRestarting in %s seconds...", e, LOOP_TIME)
        raise


if __name__ == "__main__":
    main()
