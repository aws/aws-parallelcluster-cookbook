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

import argparse
import asyncio
import hashlib
import json
import logging
import os
import re
import subprocess  # nosec B404
import tempfile
import time
from abc import ABC, abstractmethod
from builtins import RuntimeError
from dataclasses import dataclass
from datetime import datetime, timezone
from enum import Enum
from typing import Dict
from urllib.parse import urlparse

import boto3
import botocore
import requests
import yaml
from botocore.exceptions import ClientError, NoCredentialsError

BOOSTRAP_ERROR_FILE = "/var/log/parallelcluster/bootstrap_error_msg"

ERROR_MSG_SUFFIX = (
    "Please check /var/log/cfn-init.log in the head node, or check the cfn-init.log in CloudWatch logs. "
    "Please refer to https://docs.aws.amazon.com/parallelcluster/latest/ug/troubleshooting-v3.html"
    "#troubleshooting-v3-get-logs for more details on ParallelCluster logs."
)

SCRIPT_LOG_NAME_FETCH_AND_RUN = "fetch_and_run"

DOWNLOAD_SCRIPT_HTTP_TIMEOUT_SECONDS = 60


@dataclass
class ScriptDefinition:
    """Script definition for custom actions."""

    url: str
    args: list  # type list[str]


@dataclass
class ExecutableScript(ScriptDefinition):
    """Executable script for custom actions."""

    step_num: int
    path: str


class LegacyEventName(Enum):
    """Maps legacy events names to avoid changing script contract."""

    ON_NODE_START = "preinstall"
    ON_NODE_CONFIGURED = "postinstall"
    ON_NODE_UPDATED = "postupdate"

    def map_to_current_name(self):
        """Return the current event name value as it's configured in the cluster config."""
        try:
            result = LEGACY_EVENT_TO_CURRENT_NAME_MAP[self]
        except KeyError as err:
            raise ValueError(f"Unknown legacy event name: {self.value}") from err

        return result

    def __str__(self):
        """Return the legacy event name value."""
        return self.value


LEGACY_EVENT_TO_CURRENT_NAME_MAP = {
    LegacyEventName.ON_NODE_START: "OnNodeStart",
    LegacyEventName.ON_NODE_CONFIGURED: "OnNodeConfigured",
    LegacyEventName.ON_NODE_UPDATED: "OnNodeUpdated",
}


@dataclass
class CustomActionsConfig:
    """
    Encapsulates custom actions configuration.

    Contains all the configuration relevant to custom actions execution.
    """

    stack_name: str
    cluster_name: str
    region_name: str
    node_type: str
    queue_name: str
    pool_name: str
    resource_name: str
    instance_id: str
    instance_type: str
    ip_address: str
    hostname: str
    availability_zone: str
    scheduler: str
    event_name: str
    legacy_event: LegacyEventName
    can_execute: bool
    dry_run: bool
    script_sequence: list  # type list[ScriptDefinition]
    script_sequences_per_event: dict
    event_file_override: str
    node_spec_file: str


class EnvEnricher:
    """Provide the environment variables for the ExecutableScript."""

    def __init__(self):
        self._base_env = os.environ.copy()

    def build_env(self, exe_script: ExecutableScript):  # pylint: disable=unused-argument
        """Provide a copy of the current process environment variables."""
        return self._base_env.copy()


class CfnConfigEnvEnricher(EnvEnricher):
    """Provides cnfconfig backward compatible environment variables for the ExecutableScript."""

    def __init__(self, conf: CustomActionsConfig):
        super().__init__()
        self.conf = conf
        self._cfn_base_env = CfnConfigEnvEnricher._create_additional_cfnconfig_compatible_env(
            self.conf.script_sequences_per_event
        )

    @staticmethod
    def _create_additional_cfnconfig_compatible_env(script_sequences_per_event):
        additional_env = {}
        for legacy_event, script_sequence in script_sequences_per_event.items():
            script_definition = script_sequence[0] if script_sequence else None
            additional_env.update(CfnConfigEnvEnricher._create_script_env(legacy_event, script_definition))

        return additional_env

    @staticmethod
    def _create_script_env(legacy_event, script_definition):
        if script_definition is None:
            script_definition = ScriptDefinition("", [])

        script_env = {f"cfn_{legacy_event.value}": f'"{script_definition.url}"'}
        # _args is a bash array and should support expansions like "${cfn_postupdate_args[@]}"
        args = script_definition.args
        if args is None:
            args = []
        arguments = " ".join(f'"{arg}"' for arg in args)
        script_env[f"cfn_{legacy_event.value}_args"] = f"({arguments})"
        return script_env

    def build_env(self, exe_script: ExecutableScript):
        """Provide a copy of the current process environment variables."""
        full_env = super().build_env(exe_script)
        full_env.update(self._cfn_base_env)
        full_env.update(self._create_script_env(self.conf.legacy_event, exe_script))
        return full_env


class ScriptRunner:
    """Performs download and execution of scripts."""

    def __init__(self, event_name, region_name, env_enricher: EnvEnricher = None):
        self.event_name = event_name
        self.region_name = region_name
        self._env_enricher = env_enricher if env_enricher else EnvEnricher()

    async def download_and_execute_scripts(self, scripts):
        """
        Download and execute scripts.

        :param scripts:
        :return:
        """
        downloaded_scripts = await asyncio.gather(
            *[self._download_script(script, idx) for idx, script in enumerate(scripts, 1)]
        )
        for script in downloaded_scripts:
            logging.info("The hash of script %s is: %s", script.url, self._hash_of_file(script.path))
            await self._execute_script(script)
            os.unlink(script.path)

    @staticmethod
    def _hash_of_file(path):
        hash_sha256 = hashlib.sha256()
        with open(path, "rb") as file:
            while True:
                data = file.read(1024)
                if not data:
                    break
                hash_sha256.update(data)
        return hash_sha256.hexdigest()

    async def _download_script(self, script: ScriptDefinition, step_num=0) -> ExecutableScript:
        exe_script = self._build_exe_script(script, step_num, None)
        if self._is_s3_url(script.url):
            return await self._download_s3_script(exe_script)
        if self._is_https_url(script.url):
            return await self._download_http_script(exe_script)

        raise DownloadRunError(
            f"Failed to download {self.event_name} script {step_num} {script.url}, URL must be an s3 or HTTPs.",
            f"Failed to download {self.event_name} script {step_num}, URL must be an s3 or HTTPs.",
            step_id=step_num,
            stage="downloading",
        )

    @staticmethod
    def _build_exe_script(script, step_num, path):
        return ExecutableScript(script.url, script.args, step_num, path)

    async def _download_s3_script(self, exe_script: ExecutableScript):
        s3_client = boto3.resource("s3", region_name=self.region_name)
        bucket_name, key = self._parse_s3_url(exe_script.url)
        with tempfile.NamedTemporaryFile(delete=False) as file:
            try:
                s3_client.Bucket(bucket_name).download_file(key, file.name)
            except (NoCredentialsError, botocore.exceptions.ClientError) as err:
                os.unlink(file.name)
                raise DownloadRunError(
                    f"Failed to download {self.event_name} script {exe_script.step_num} {exe_script.url}"
                    f" using aws s3, cause: {err}.",
                    f"Failed to download {self.event_name} script {exe_script.step_num} using aws s3.",
                    step_id=exe_script.step_num,
                    stage="downloading",
                    error=str(err),
                ) from err
            exe_script.path = file.name
            return exe_script

    async def _download_http_script(self, exe_script: ExecutableScript):
        url = exe_script.url
        response = requests.get(url, timeout=DOWNLOAD_SCRIPT_HTTP_TIMEOUT_SECONDS)
        if response.status_code != 200:
            raise DownloadRunError(
                f"Failed to download {self.event_name} script {exe_script.step_num} {url}, "
                f"HTTP status code {response.status_code}.",
                f"Failed to download {self.event_name} script {exe_script.step_num} via HTTP.",
                step_id=exe_script.step_num,
                stage="downloading",
                error={
                    "status_code": response.status_code,
                    "status_reason": response.reason,
                },
            )
        with tempfile.NamedTemporaryFile(delete=False) as file:
            file.write(response.content)
        exe_script.path = file.name
        return exe_script

    async def _execute_script(self, exe_script: ExecutableScript, stdout=None):
        # preserving error case for making the script executable
        try:
            subprocess.run(
                ["chmod", "+x", exe_script.path], check=True, stderr=subprocess.PIPE
            )  # nosec - trusted input
        except subprocess.CalledProcessError as err:
            raise DownloadRunError(
                f"Failed to run {self.event_name} script {exe_script.step_num} {exe_script.url} "
                f"due to a failure in making the file executable, return code: {err.returncode}.",
                f"Failed to run {self.event_name} script {exe_script.step_num} "
                f"due to a failure in making the file executable, return code: {err.returncode}.",
                step_id=exe_script.step_num,
                stage="executing",
                error={
                    "exit_code": err.returncode,
                    "stderr": str(err.stderr),
                },
            ) from err

        # execute script with it's args
        try:
            # arguments are provided by the user who has the privilege to create/update the cluster
            subprocess.run(
                [exe_script.path] + (exe_script.args or []),
                check=True,
                stderr=subprocess.PIPE,
                stdout=stdout,
                text=True,
                env=self._env_enricher.build_env(exe_script),
            )  # nosec - trusted input
        except subprocess.CalledProcessError as err:
            raise DownloadRunError(
                f"Failed to execute {self.event_name} script {exe_script.step_num} {exe_script.url},"
                f" return code: {err.returncode}.",
                f"Failed to execute {self.event_name} script {exe_script.step_num}, return code: {err.returncode}.",
                step_id=exe_script.step_num,
                stage="executing",
                error={
                    "exit_code": err.returncode,
                    "stderr": str(err.stderr),
                },
            ) from err

    @staticmethod
    def _is_https_url(url):
        return urlparse(url).scheme == "https"

    @staticmethod
    def _is_s3_url(url):
        return urlparse(url).scheme == "s3"

    @staticmethod
    def _parse_s3_url(url):
        parsed_url = urlparse(url)
        return parsed_url.netloc, parsed_url.path.lstrip("/")


class CustomLogger(ABC):
    """Abstract base class for custom loggers."""

    def __init__(self, conf: CustomActionsConfig):
        self.conf = conf

    @abstractmethod
    def error_exit_with_bootstrap_error(
            self, msg: str, msg_without_url: str = None, step: int = None, stage: str = None, error: any = None
    ):
        """
        Log error message and exit with a bootstrap error.

        :param error:
        :param stage: downloading | executing
        :param step: action index
        :param msg: error message
        :param msg_without_url: alternate error message with the URL masked
        """
        pass

    def error_exit(self, msg: str):
        """
        Log error message and exit.

        :param msg: error message
        """
        self._log_message(msg)
        raise SystemExit(1)

    def _log_message(self, message: str):
        print(message)
        if not self.conf.dry_run:
            subprocess.run(["logger", "-t", "parallelcluster", message], check=True)  # nosec - trusted input

    def _write_bootstrap_error(self, message):
        output_path = self.conf.event_file_override
        if self.conf.dry_run:
            print(f"Would write to {output_path}, message: {message}")
            return

        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(f"{message}\n")

    def _get_event(self, message: str, step: int = None, stage: str = None, error: any = None):
        now = datetime.now(timezone.utc).isoformat(timespec="milliseconds")

        return {
            "datetime": now,
            "version": 0,
            "scheduler": "slurm",
            "cluster-name": self.conf.cluster_name,
            "node-role": self.conf.node_type,
            "component": "custom-action",
            "level": "ERROR",
            "instance-id": self.conf.instance_id,
            "event-type": "custom-action-error",
            "message": message,
            "detail": {
                "action": self.conf.event_name,
                "step": step,
                "stage": stage,
                "error": error,
            }
        }


class HeadNodeLogger(CustomLogger):
    """
    Logs using the same logic as the legacy bash script.

    Could be changed to a standard logger when error signaling is more testable.
    """

    def __init__(self, conf: CustomActionsConfig):
        super().__init__(conf)

    def error_exit_with_bootstrap_error(
        self, msg: str, msg_without_url: str = None, step: int = None, stage: str = None, error: any = None
    ):
        """Log error message and exit with a bootstrap error."""
        self._log_message(f"{SCRIPT_LOG_NAME_FETCH_AND_RUN} - {msg} {ERROR_MSG_SUFFIX}")

        message = msg_without_url if msg_without_url else msg
        self._write_bootstrap_error(message=f"{SCRIPT_LOG_NAME_FETCH_AND_RUN} - {message} {ERROR_MSG_SUFFIX}")

        raise SystemExit(1)


class ComputeFleetLogger(CustomLogger):
    """
    Logs using the same logic as the legacy bash script.

    Could be changed to a standard logger when error signaling is more testable.

    Example Event:
    {
        "datetime": "2023-03-22T22:40:34.524+00:00",
        "version": 0,
        "scheduler": "slurm",
        "cluster-name": "integ-tests-t7cx6bzjwuokd1oj",
        "node-role": "ComputeFleet",
        "component": "custom-action",
        "level": "ERROR",
        "instance-id": "i-0036f2c5a7fdc7a25",
        "compute": {
            "name": "queue-1-dy-compute-a-1",
            "instance-id": "i-0036f2c5a7fdc7a25",
            "instance-type": "c5.xlarge",
            "availability-zone": "us-east-1d",
            "address": "192.168.111.173",
            "hostname": "ip-192-168-111-173.ec2.internal",
            "queue-name": "queue-1",
            "compute-resource": "compute-a",
            "node-type": "dynamic"
        },
        "event-type": "custom-action-error",
        "message": "Failed to download OnNodeConfigured script 1 using aws s3.",
        "detail": {
            "action": "OnNodeConfigured",
            "step": 1,
            "stage": "downloading",
            "error": "An error occurred (404) when calling the HeadObject operation: Not Found"
        }
    }
    """

    def __init__(self, conf: CustomActionsConfig):
        super().__init__(conf)
        self._node_name_pattern = re.compile(r"^[a-z0-9\-]+-(st|dy)-[a-z0-9\-]+-\d+$")

    def error_exit_with_bootstrap_error(
        self, msg: str, msg_without_url: str = None, step: int = None, stage: str = None, error: any = None
    ):
        """Log error message and exit with a bootstrap error."""
        message = msg_without_url if msg_without_url else msg
        event = self._get_event(message, step, stage, error)

        node_spec = self._get_node_spec()
        compute = event.setdefault("compute", {})
        compute.update(
            {
                "name": node_spec.get("name"),
                "instance-id": self.conf.instance_id,
                "instance-type": self.conf.instance_type,
                "availability-zone": self.conf.availability_zone,
                "address": self.conf.ip_address,
                "hostname": self.conf.hostname,
                "queue-name": self.conf.queue_name,
                "compute-resource": self.conf.resource_name,
                "node-type": node_spec.get("type"),
            }
        )

        self._write_bootstrap_error(message=json.dumps(event))
        # Need to give CloudWatch Agent time to publish the error log
        time.sleep(5)
        self.error_exit(msg)

    def _get_node_spec(self) -> Dict[str, str]:
        if self.conf.node_spec_file:
            try:
                node_name = ComputeFleetLogger._read_node_name(self.conf.node_spec_file)
                return {
                    "name": node_name if node_name else "unknown",
                    "type": self._get_node_type(node_name),
                }
            except Exception as e:
                logging.error("Failed to load node spec file: %s", e)
        return {
            "name": "unknown",
            "type": "unknown",
        }

    def _get_node_type(self, node_name: str) -> str:
        if node_name:
            match = self._node_name_pattern.match(node_name)
            if match:
                return "static" if match.group(1) == "st" else "dynamic"
        return "unknown"

    @staticmethod
    def _read_node_name(node_spec_path: str) -> str:
        with open(node_spec_path, "r", encoding="utf-8") as node_spec_file:
            return node_spec_file.read().strip()


class LoginNodesLogger(CustomLogger):

    def __init__(self, conf: CustomActionsConfig):
        super().__init__(conf)

    def error_exit_with_bootstrap_error(
            self, msg: str, msg_without_url: str = None, step: int = None, stage: str = None, error: any = None
    ):
        """Log error message and exit with a bootstrap error."""
        self._log_message(f"{SCRIPT_LOG_NAME_FETCH_AND_RUN} - {msg} {ERROR_MSG_SUFFIX}")
        message = msg_without_url if msg_without_url else msg
        event = self._get_event(message, step, stage, error)

        login = event.setdefault("login", {})
        login.update(
            {
                "pool-name": self.conf.pool_name,
                "instance-id": self.conf.instance_id,
                "instance-type": self.conf.instance_type,
                "availability-zone": self.conf.availability_zone,
                "address": self.conf.ip_address,
                "hostname": self.conf.hostname,
            }
        )

        self._write_bootstrap_error(message=json.dumps(event))
        time.sleep(5)
        self.error_exit(msg)


class ConfigLoader:
    """
    Encapsulates configuration handling logic.

    Loads custom actions relevant configuration from the provided cluster configuration file according to the node type,
    event  and queue.
    """

    @staticmethod
    def _load_cluster_config(input_file_path):
        """Load cluster config file."""
        with open(input_file_path, encoding="utf-8") as input_file:
            return yaml.load(input_file, Loader=yaml.SafeLoader)

    def load_configuration(self, args) -> CustomActionsConfig:
        """
        Load configuration.

        :param args: command line arguments
        :return: configuration object
        """
        node_type = args.node_type
        queue_name = args.queue_name
        pool_name = args.pool_name

        cluster_config = self._load_cluster_config(args.cluster_configuration)
        logging.debug(cluster_config)

        legacy_event = None
        event_name = None
        script_sequences_per_event = {}
        for event in LegacyEventName:
            current_event_name = event.map_to_current_name()
            script_sequences_per_event[event] = self._deserialize_script_sequences(
                cluster_config, current_event_name, node_type, queue_name, pool_name
            )
            if getattr(args, event.value):
                legacy_event = event
                event_name = current_event_name

        script_sequence = script_sequences_per_event[legacy_event]

        conf = CustomActionsConfig(
            legacy_event=legacy_event,
            node_type=node_type,
            queue_name=queue_name,
            event_name=event_name,
            pool_name=args.pool_name,
            region_name=args.region,
            stack_name=args.stack_name,
            cluster_name=args.cluster_name,
            script_sequence=script_sequence,
            script_sequences_per_event=script_sequences_per_event,
            dry_run=args.dry_run,
            can_execute=len(script_sequence) > 0,
            instance_id=args.instance_id,
            instance_type=args.instance_type,
            ip_address=args.ip_address,
            hostname=args.hostname,
            scheduler=args.scheduler,
            availability_zone=args.availability_zone,
            resource_name=args.resource_name,
            event_file_override=args.event_file_override,
            node_spec_file=args.node_spec_file,
        )

        logging.debug(conf)

        return conf

    def _deserialize_script_sequences(self, cluster_config, event_name, node_type, queue_name, pool_name):
        # this is a good candidate for sharing logic with pcluster as library on the nodes
        try:
            if node_type == "HeadNode":
                script_data = cluster_config["HeadNode"]["CustomActions"][event_name]
            elif node_type == "LoginNode":
                script_data = next(
                    (
                        pool for pool in cluster_config["LoginNodes"]["Pools"]
                        if pool["Name"] == pool_name and pool["CustomActions"]
                    ),
                    None
                )["CustomActions"][event_name]
            else:
                script_data = next(
                    (
                        queue
                        for queue in next(
                            list_value
                            for list_value in cluster_config["Scheduling"].values()
                            if isinstance(list_value, list)
                        )
                        if queue["Name"] == queue_name and queue["CustomActions"]
                    ),
                    None,
                )["CustomActions"][event_name]

            sequence = self._extract_script_sequence(script_data)
        except (KeyError, TypeError) as err:
            logging.debug("Ignoring missing %s in configuration, cause: %s", event_name, err)
            sequence = []
        return sequence

    @staticmethod
    def _extract_script_sequence(data):
        sequence = []
        if not data:
            pass
        elif "Script" in data:
            sequence = [data]
        elif "Sequence" in data and isinstance(data["Sequence"], list):
            sequence = data["Sequence"]
        return [ScriptDefinition(url=s["Script"], args=s["Args"]) for s in sequence]


class DownloadRunError(Exception):
    """Error in script execution supporting masking of script urls in the logs."""

    def __init__(self, msg, msg_without_url, step_id: int = None, stage: str = None, error: any = None):
        self.msg = msg
        self.msg_without_url = msg_without_url
        self.step_id = step_id
        self.stage = stage
        self.step_id = step_id
        self.error = error


class ActionRunner:
    """Encapsulates the logic to map configured supported events to executable scripts."""

    def __init__(self, conf: CustomActionsConfig, custom_logger: CustomLogger):
        self.conf = conf
        self.custom_logger = custom_logger

    def run(self):
        """Execute the custom action scripts configured for the event."""
        actions = {
            LegacyEventName.ON_NODE_START: self._on_node_start,
            LegacyEventName.ON_NODE_CONFIGURED: self._on_node_configured,
            LegacyEventName.ON_NODE_UPDATED: self._on_node_updated,
        }
        actions.get(self.conf.legacy_event, self._unknown_action)()

    def _on_node_bootstrap_event(self):
        if self.conf.can_execute:
            try:
                self._download_run()
            except DownloadRunError as e:
                self.custom_logger.error_exit_with_bootstrap_error(
                    msg=e.msg, msg_without_url=e.msg_without_url, step=e.step_id, stage=e.stage, error=e.error
                )
            except RuntimeError as e:
                logging.debug(e)
                self.custom_logger.error_exit_with_bootstrap_error(f"Failed to run {self.conf.event_name} script.")

    def _on_node_start(self):
        self._on_node_bootstrap_event()

    def _on_node_configured(self):
        self._on_node_bootstrap_event()

    def _on_node_updated(self):
        if self.conf.can_execute and self._is_stack_update_in_progress():
            try:
                self._download_run()
            except DownloadRunError as e:
                self.custom_logger.error_exit(msg=e.msg)
            except RuntimeError as e:
                logging.debug(e)
                self.custom_logger.error_exit("Failed to run post update hook")

    def _download_run(self):
        if self.conf.dry_run:
            print("Dry run, would download and execute scripts:")
            for script in self.conf.script_sequence:
                print(f"  {script.url} with args {script.args}")
        else:
            asyncio.run(
                ScriptRunner(
                    self.conf.event_name,
                    self.conf.region_name,
                    CfnConfigEnvEnricher(self.conf),
                ).download_and_execute_scripts(self.conf.script_sequence)
            )

    def _get_stack_status(self) -> str:
        stack_status = "UNKNOWN"
        try:
            cloudformation = boto3.client("cloudformation", region_name=self.conf.region_name)
            response = cloudformation.describe_stacks(StackName=self.conf.stack_name)
            stack_status = response["Stacks"][0]["StackStatus"]
        except (KeyError, ClientError, botocore.exceptions.ParamValidationError) as e:
            logging.debug(e)
            self.custom_logger.error_exit(
                "Failed to get the stack status, check the HeadNode instance profile's IAM policies"
            )
        return stack_status

    def _is_stack_update_in_progress(self):
        stack_status = self._get_stack_status()
        if stack_status != "UPDATE_IN_PROGRESS":
            print(f"Post update hook called with CFN stack in state {stack_status}, doing nothing")
            result = False
        else:
            result = True
        return result

    @staticmethod
    def _unknown_action():
        print("Unknown action. Exit gracefully")
        raise SystemExit(1)


def _parse_cli_args():
    parser = argparse.ArgumentParser(
        description="Execute action scripts attached to a node lifecycle event", exit_on_error=False
    )

    event_group = parser.add_mutually_exclusive_group(required=True)

    for event in LegacyEventName:
        event_group.add_argument(
            f"-{event.value}",
            action="store_true",
            help=f"selects the {event.value} event in the node lifecycle to execute",
        )

    parser.add_argument(
        "-r",
        "--region",
        type=str,
        default=os.getenv("AWS_REGION", None),
        required=False,
        help="the cluster AWS region, defaults to AWS_REGION env variable",
    )
    parser.add_argument(
        "-s",
        "--stack-name",
        type=str,
        default=os.getenv("PCLUSTER_STACK_NAME", None),
        required=False,
        help="the parallelcluster cloudformation stack name," " defaults to PCLUSTER_STACK_NAME env variable",
    )
    parser.add_argument(
        "-n",
        "--node-type",
        type=str,
        default=os.getenv("PCLUSTER_NODE_TYPE", None),
        required=False,
        help="the node type, defaults to PCLUSTER_NODE_TYPE env variable",
    )
    parser.add_argument(
        "-q",
        "--queue-name",
        type=str,
        default=os.getenv("PCLUSTER_SCHEDULER_QUEUE_NAME", None),
        required=False,
        help="the scheduler queue name, defaults to PCLUSTER_SCHEDULER_QUEUE_NAME env variable",
    )
    parser.add_argument(
        "-p",
        "--pool-name",
        default=os.getenv("PCLUSTER_LOGIN_NODES_POOL_NAME", None),
        required=False,
        help="the login node pool name, defaults to PCLUSTER_LOGIN_NODES_POOL_NAME env variable",
    )
    parser.add_argument(
        "-c",
        "--cluster-configuration",
        type=str,
        default="/opt/parallelcluster/shared/cluster-config.yaml",
        required=False,
        help="the cluster config file, defaults to " "/opt/parallelcluster/shared/cluster-config.yaml",
    )
    parser.add_argument(
        "--instance-id",
        type=str,
        default=None,
        required=False,
        help="the EC2 instance ID",
    )
    parser.add_argument(
        "--instance-type",
        type=str,
        default=None,
        required=False,
        help="the EC2 instance type",
    )
    parser.add_argument(
        "--ip-address",
        type=str,
        default=None,
        required=False,
        help="the IP address of this host",
    )
    parser.add_argument(
        "--hostname",
        type=str,
        default=None,
        required=False,
        help="the name of this host",
    )
    parser.add_argument(
        "--resource-name", type=str, default=None, help="the name of the compute resource pool this host belongs to"
    )
    parser.add_argument(
        "--availability-zone", type=str, default=None, help="the availability zone this host is deployed to"
    )
    parser.add_argument("--cluster-name", type=str, default=None, help="the cluster name")
    parser.add_argument("--scheduler", type=str, default=None, help="the cluster scheduler type")
    parser.add_argument("--verbose", "-v", action="store_true", help="enable verbose logging")
    parser.add_argument("--dry-run", "-d", action="store_true", help="enable dry run")
    parser.add_argument("--execute-via-cfnconfig", "-e", action="store_true", help="execute via cfnconfig")
    parser.add_argument(
        "--event-file-override", type=str, default=BOOSTRAP_ERROR_FILE, help="override event output file path"
    )
    parser.add_argument(
        "--node-spec-file", type=str, default=None, required=False, help="path to file containing node description"
    )

    try:
        args = parser.parse_args()
    except SystemExit as e:
        e.code = 1
        raise e

    return args


CUSTOM_LOGGER = {
    "HeadNode": HeadNodeLogger,
    "ComputeFleet": ComputeFleetLogger,
    "LoginNode": LoginNodesLogger,
}


def main():
    try:
        args = _parse_cli_args()

        if args.verbose:
            logging.basicConfig(level=logging.DEBUG)

        if args.execute_via_cfnconfig:
            logging.warning(
                "Execution via cfnconfig env variables is discouraged! Current related env values:\n"
                "cfn_preinstall=%s\ncfn_preinstall_args=%s\ncfn_postinstall=%s\ncfn_postinstall_args=%s\n"
                "cfn_postupdate=%s\ncfn_postupdate_args=%s\n"
                "Please mind that the cfn_* env variables will be ignored and the action will be executed "
                "using the cluster configuration available in %s.\n",
                os.getenv("cfn_preinstall", ""),
                os.getenv("cfn_preinstall_args", ""),
                os.getenv("cfn_postinstall", ""),
                os.getenv("cfn_postinstall_args", ""),
                os.getenv("cfn_postupdate", ""),
                os.getenv("cfn_postupdate_args", ""),
                args.cluster_configuration,
            )

        conf = ConfigLoader().load_configuration(args)
        ActionRunner(conf, CUSTOM_LOGGER.get(conf.node_type, ComputeFleetLogger)(conf)).run()

    except Exception as err:
        logging.exception(err)
        print(f"ERROR: Unexpected exception: {err}")
        raise SystemExit(1) from err

    logging.debug("Completed with success.")
    raise SystemExit(0)


if __name__ == "__main__":
    main()

