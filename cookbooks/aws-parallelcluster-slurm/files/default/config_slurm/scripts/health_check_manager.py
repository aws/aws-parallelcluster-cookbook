#!/usr/bin/env python
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

# FIXME: Fix Code Duplication
# pylint: disable=R0801

import argparse
import logging
import os
import shlex

# A nosec comment is appended to the following line in order to disable the B404 check.
# In this file the input of the module subprocess is trusted.
import subprocess  # nosec B404
from builtins import Exception, KeyError, SystemExit, TypeError, bool, int, next, repr, staticmethod, str
from configparser import ConfigParser
from dataclasses import dataclass
from enum import Enum
from io import StringIO
from logging.config import fileConfig
from typing import List

import yaml
from event_utils import (
    EventPublisher,
    get_node_spec_from_file,
    publish_health_check_exception,
    publish_health_check_result,
)

CONFIG_FILE_DIR = os.path.join(os.path.dirname(__file__), "conf")
FILE_READ_TIMEOUT = 30

log = logging.getLogger(__name__)
event_logger = logging.getLogger("slurm_plugin.prolog.events")


class ManagedHealthCheckName(Enum):
    """Enum that identifies the managed Health Checks and their command script."""

    GPU = "gpu_health_check.sh"

    def get_health_check_path(self, managed_health_check_dir: str) -> str:
        """Return the file path of the health check."""
        return os.path.join(managed_health_check_dir, self.value)


def _read_file(file_path: str) -> str:
    # Use subprocess command to get shared file content to prevent hanging when NFS is down
    # The command in this subprocess call is built as literal
    result = subprocess.run(
        shlex.split(f"cat {str(file_path)}"),
        timeout=FILE_READ_TIMEOUT,
        stdout=subprocess.PIPE,
        encoding="utf-8",
        check=False,
        shell=False,  # nosec B603
    )
    return result.stdout if hasattr(result, "stdout") else ""


class HealthCheckManagerConfig:
    """Class that identifies the Health Check Manager configuration."""

    DEFAULTS = {
        "health_check_timeout": 600,
        "logging_config": os.path.join(os.path.dirname(__file__), "logging", "health_check_manager_logging.conf"),
        "managed_health_check_dir": os.path.join(os.path.dirname(__file__), "health_checks"),
    }

    def __init__(self, config_file_path):
        self._get_config(config_file_path)

    def __repr__(self):
        """Return Health Check Manager configuration representation."""
        attrs = ", ".join([f"{key}={repr(value)}" for key, value in self.__dict__.items()])
        return f"{self.__class__.__name__}({attrs})"

    def __eq__(self, other):
        """Return true if both objects are equal."""
        if type(other) is type(self):
            return self._config == other._config
        return False

    def __ne__(self, other):
        """Return true if both objects are not equal."""
        return not self.__eq__(other)

    def _get_config(self, config_file_path: str):
        """Get health check manager configuration."""
        log.info("Reading '%s'", config_file_path)

        self._config = ConfigParser()
        try:
            self._config.read_file(StringIO(_read_file(config_file_path)))
        except Exception as err:
            if hasattr(err, "message"):
                err = err.message
            log.error(
                "Cannot read Health Check Manager config file: %s, falling back to default settings. Error is: %s",
                config_file_path,
                err,
            )

        self.health_check_timeout = self._config.getint(
            "health_check_manager", "health_check_timeout", fallback=self.DEFAULTS.get("health_check_timeout")
        )
        self.logging_config = self._config.get(
            "health_check_manager", "logging_config", fallback=self.DEFAULTS.get("logging_config")
        )
        self.managed_health_check_dir = self._config.get(
            "health_check_manager", "managed_health_check_dir", fallback=self.DEFAULTS.get("managed_health_check_dir")
        )

        log.debug(repr(self))


@dataclass
class HealthCheckDefinition:
    """
    Health Check definition.

    Contains all the configuration relevant to a specific health check.
    """

    name: str
    is_managed: bool
    is_enabled: bool
    check_path: str


@dataclass
class HealthCheckConfig:
    """
    Health Check configuration.

    Contains all the configuration relevant to all the health checks.
    """

    node_type: str
    queue_name: str
    compute_resource_name: str
    health_checks: List[HealthCheckDefinition]


class HealthCheckConfigLoader:
    """
    Health Check configuration loader.

    Loads Health Check configuration from cluster configuration file according to the node type,
    queue and compute resource.
    """

    @staticmethod
    def _load_cluster_config(input_file_path: str) -> str:
        """Load cluster config file."""
        return yaml.load(StringIO(_read_file(input_file_path)), Loader=yaml.SafeLoader)

    def load_configuration(
        self, health_check_manager_config: HealthCheckManagerConfig, args: argparse.Namespace
    ) -> HealthCheckConfig:
        """
        Load Health Check configuration.

        :param health_check_manager_config: Health Check Manager configuration
        :param args: command line arguments
        :return: Health Check configuration object
        """
        cluster_config = self._load_cluster_config(args.cluster_configuration)

        log.debug("Cluster config: %s", cluster_config)

        health_checks = []
        try:
            if args.node_type == "ComputeFleet":
                queues = cluster_config["Scheduling"]["SlurmQueues"]

                queue = next((queue for queue in queues if queue["Name"] == args.queue_name), None)
                compute_resource = next(
                    (
                        compute_resource
                        for compute_resource in queue["ComputeResources"]
                        if compute_resource["Name"] == args.compute_resource_name
                    ),
                    None,
                )

                for health_check_key, health_check_value in compute_resource["HealthChecks"].items():
                    if health_check_key == "CustomChecks":
                        # not yet implemented
                        pass
                    else:
                        health_check = HealthCheckDefinition(
                            name=health_check_key,
                            is_managed=True,
                            is_enabled=bool(
                                health_check_value.get("Enabled")
                                if health_check_value.get("Enabled") is not None
                                else queue["HealthChecks"][health_check_key].get("Enabled", False)
                            ),
                            check_path=ManagedHealthCheckName[health_check_key.upper()].get_health_check_path(
                                health_check_manager_config.managed_health_check_dir
                            ),
                        )
                        health_checks.append(health_check)

        except (KeyError, TypeError) as err:
            if hasattr(err, "message"):
                err = err.message
            log.warning("Ignore missing %s in config", err)

        health_check_conf = HealthCheckConfig(
            node_type=args.node_type,
            queue_name=args.queue_name,
            compute_resource_name=args.compute_resource_name,
            health_checks=health_checks,
        )

        log.debug("HealthCheck config %s: ", health_check_conf)
        return health_check_conf


def _execute_health_checks(health_check_manager_config: HealthCheckManagerConfig, args: argparse.Namespace) -> int:
    """Execute all Health Check."""
    health_check_conf = HealthCheckConfigLoader().load_configuration(health_check_manager_config, args)

    event_publisher = _get_event_publisher(args)

    exit_code_sum = 0

    for health_check in health_check_conf.health_checks:
        if health_check.is_enabled:
            try:
                log.info(
                    "Executing Health Check '%s' for queue '%s' and compute resource '%s'",
                    health_check.name,
                    health_check_conf.queue_name,
                    health_check_conf.compute_resource_name,
                )

                # The command in this subprocess call is built as literal
                result = subprocess.run(
                    health_check.check_path,
                    timeout=health_check_manager_config.health_check_timeout,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    encoding="utf-8",
                    check=False,
                    shell=False,  # nosec B603
                )
                exit_code_sum += result.returncode
                if result.stdout:
                    output = f":\n{result.stdout}"
                else:
                    output = " empty"
                log.info("Output of Health Check '%s' execution is%s", health_check.name, output)
                publish_health_check_result(
                    event_publisher, args.job_id, health_check.name, result.returncode, result.stdout
                )
            except (subprocess.SubprocessError, OSError) as err:
                if hasattr(err, "message"):
                    err = err.message
                log.error(
                    "Failure when executing Health Check '%s' for queue '%s' and compute resource '%s', with error: %s",
                    health_check.name,
                    health_check_conf.queue_name,
                    health_check_conf.compute_resource_name,
                    err,
                )
                publish_health_check_exception(event_publisher, args.job_id, health_check.name, err)
    if not health_check_conf.health_checks:
        log.info("No Health Check enabled found")

    return exit_code_sum


def _parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Health Check Manager")
    parser.add_argument(
        "-n",
        "--node-type",
        required=False,
        help="Node type",
    )
    parser.add_argument(
        "-q",
        "--queue-name",
        required=False,
        help="Scheduler queue name",
    )
    parser.add_argument(
        "-cr",
        "--compute-resource-name",
        required=False,
        help="Scheduler compute resource name",
    )
    parser.add_argument(
        "-j",
        "--job-id",
        required=False,
        help="Job ID",
    )
    parser.add_argument(
        "-c",
        "--cluster-configuration",
        required=True,
        help="Path to cluster configuration",
    )
    parser.add_argument("--node-spec-file", required=False, help="File path to compute node description")
    args = parser.parse_args()
    return args


def _get_event_publisher(args: argparse.Namespace):
    node_spec = get_node_spec_from_file(args.node_spec_file)
    return EventPublisher(event_logger=event_logger, component="health-check-manager", **node_spec)


def main():
    default_log_file = "/var/log/parallelcluster/slurm_health_check.log"
    logging.basicConfig(
        filename=default_log_file,
        level=logging.INFO,
        format="%(asctime)s - [%(filename)s:%(funcName)s] - %(levelname)s - JobID %(job_id)s - %(message)s",
    )

    try:
        args = _parse_arguments()
        # Override global log object
        global log  # pylint: disable=W0603
        log = logging.LoggerAdapter(log, {"job_id": args.job_id})
        log.info("HealthCheckManager startup.")

        config_file = os.environ.get("CONFIG_FILE", os.path.join(CONFIG_FILE_DIR, "health_check_manager.conf"))
        health_check_manager_config = HealthCheckManagerConfig(config_file)
        try:
            # Configure root logger
            fileConfig(health_check_manager_config.logging_config, disable_existing_loggers=False)
        except Exception as err:
            if hasattr(err, "message"):
                err = err.message
            log.warning(
                "Unable to configure logging from %s, using default settings and writing to %s.\nException: %s",
                health_check_manager_config.logging_config,
                default_log_file,
                err,
            )
        log.info(f"HealthCheckManager config: {health_check_manager_config}")
        exit_code = _execute_health_checks(health_check_manager_config, args)
        log.info(f"HealthCheckManager finished with exit code '{exit_code}'.")
        raise SystemExit(exit_code)

    except Exception as err:
        if hasattr(err, "message"):
            err = err.message
        log.exception("Encountered exception when running Health Check Manager, exiting gracefully: %s", err)
        raise SystemExit(0)


if __name__ == "__main__":
    main()
