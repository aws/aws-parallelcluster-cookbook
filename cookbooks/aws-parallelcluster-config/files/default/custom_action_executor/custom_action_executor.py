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
import logging
import os
import subprocess  # nosec B404
import tempfile
from builtins import RuntimeError
from dataclasses import dataclass
from enum import Enum
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


class ScriptRunner:
    """Performs download and execution of scripts."""

    def __init__(self, event_name):
        self.event_name = event_name

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
            await self._execute_script(script)
            os.unlink(script.path)

    async def _download_script(self, script: ScriptDefinition, step_num=0) -> ExecutableScript:
        exe_script = self._build_exe_script(script, step_num, None)
        if self._is_s3_url(script.url):
            return await self._download_s3_script(exe_script)
        if self._is_https_url(script.url):
            return await self._download_http_script(exe_script)

        raise DownloadRunError(
            f"Failed to download {self.event_name} script {step_num} {script.url}, URL must be an s3 or HTTPs.",
            f"Failed to download {self.event_name} script {step_num}, URL must be an s3 or HTTPs.",
        )

    @staticmethod
    def _build_exe_script(script, step_num, path):
        return ExecutableScript(script.url, script.args, step_num, path)

    async def _download_s3_script(self, exe_script: ExecutableScript):
        s3_client = boto3.resource("s3")
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
            )
        with tempfile.NamedTemporaryFile(delete=False) as file:
            file.write(response.content)
        exe_script.path = file.name
        return exe_script

    async def _execute_script(self, exe_script: ExecutableScript):
        # preserving error case for making the script executable
        try:
            subprocess.run(["chmod", "+x", exe_script.path], check=True)  # nosec - trusted input
        except subprocess.CalledProcessError as err:
            raise DownloadRunError(
                f"Failed to run {self.event_name} script {exe_script.step_num} {exe_script.url} "
                f"due to a failure in making the file executable, return code: {err.returncode}.",
                f"Failed to run {self.event_name} script {exe_script.step_num} "
                f"due to a failure in making the file executable, return code: {err.returncode}.",
            ) from err

        # execute script with it's args
        try:
            # arguments are provided by the user who has the privilege to create/update the cluster
            subprocess.run([exe_script.path] + (exe_script.args or []), check=True)  # nosec - trusted input
        except subprocess.CalledProcessError as err:
            raise DownloadRunError(
                f"Failed to execute {self.event_name} script {exe_script.step_num} {exe_script.url},"
                f" return code: {err.returncode}.",
                f"Failed to execute {self.event_name} script {exe_script.step_num}, return code: {err.returncode}.",
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


class LegacyEventName(Enum):
    """Maps legacy events names to avoid changing script contract."""

    ON_NODE_START = "preinstall"
    ON_NODE_CONFIGURED = "postinstall"
    ON_NODE_UPDATED = "postupdate"

    def map_to_current_name(self):
        """Return the current event name value as it's configured in the cluster config."""
        if self == LegacyEventName.ON_NODE_START:
            result = "OnNodeStart"
        elif self == LegacyEventName.ON_NODE_CONFIGURED:
            result = "OnNodeConfigured"
        elif self == LegacyEventName.ON_NODE_UPDATED:
            result = "OnNodeUpdated"
        else:
            raise ValueError(f"Unknown legacy event name: {self.value}")

        return result

    def __str__(self):
        """Return the legacy event name value."""
        return self.value


@dataclass
class CustomActionsConfig:
    """
    Encapsulates custom actions configuration.

    Contains all the configuration relevant to custom actions execution.
    """

    stack_name: str
    region_name: str
    node_type: str
    queue_name: str
    event_name: str
    legacy_event: LegacyEventName
    can_execute: bool
    dry_run: bool
    script_sequence: list  # type list[ScriptDefinition]


class CustomLogger:
    """
    Logs using the same logic as the legacy bash script.

    Could be changed to a standard logger when error signaling is more testable.
    """

    def __init__(self, conf: CustomActionsConfig):
        self.conf = conf

    def error_exit_with_bootstrap_error(self, msg: str, msg_without_url: str = None):
        """
        Log error message and exit with a bootstrap error.

        :param msg: error message
        :param msg_without_url: alternate error message with the URL masked
        """
        self._log_message(msg)
        self._write_bootstrap_error(msg_without_url if msg_without_url else msg)
        raise SystemExit(1)

    def _write_bootstrap_error(self, message):
        if self.conf.dry_run:
            print(f"Would write to {BOOSTRAP_ERROR_FILE}, message: {message}")
            return

        os.makedirs(os.path.dirname(BOOSTRAP_ERROR_FILE), exist_ok=True)
        with open(BOOSTRAP_ERROR_FILE, "w", encoding="utf-8") as f:
            f.write(message)

    def error_exit(self, msg: str):
        """
        Log error message and exit.

        :param msg: error message
        """
        self._log_message(msg)
        raise SystemExit(1)

    def _log_message(self, msg: str):
        complete_message = f"{SCRIPT_LOG_NAME_FETCH_AND_RUN} - {msg} {ERROR_MSG_SUFFIX}"
        print(complete_message)
        if not self.conf.dry_run:
            subprocess.run(["logger", "-t", "parallelcluster", complete_message], check=True)  # nosec - trusted input


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
        legacy_event = None
        for event in LegacyEventName:
            if getattr(args, event.value):
                legacy_event = event
                break
        event_name = legacy_event.map_to_current_name()
        cluster_config = self._load_cluster_config(args.cluster_configuration)

        logging.debug(cluster_config)

        try:
            if args.node_type == "HeadNode":
                data = cluster_config["HeadNode"]["CustomActions"][event_name]
            else:
                data = next(
                    (
                        q
                        for q in next(v for v in cluster_config["Scheduling"].values() if isinstance(v, list))
                        if q["Name"] == args.queue_name and q["CustomActions"]
                    ),
                    None,
                )["CustomActions"][event_name]

            sequence = self._extract_script_sequence(data)
        except (KeyError, TypeError) as err:
            logging.debug("Ignoring missing %s in configuration, cause: %s", event_name, err)
            sequence = []

        conf = CustomActionsConfig(
            legacy_event=legacy_event,
            node_type=args.node_type,
            queue_name=args.queue_name,
            event_name=event_name,
            region_name=args.region,
            stack_name=args.stack_name,
            script_sequence=sequence,
            dry_run=args.dry_run,
            can_execute=len(sequence) > 0,
        )

        logging.debug(conf)

        return conf

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

    def __init__(self, msg, msg_with_url):
        self.msg = msg
        self.msg_with_url = msg_with_url


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
                self.custom_logger.error_exit_with_bootstrap_error(msg=e.msg, msg_without_url=e.msg_with_url)
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
            asyncio.run(ScriptRunner(self.conf.event_name).download_and_execute_scripts(self.conf.script_sequence))

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
        "-c",
        "--cluster-configuration",
        type=str,
        default="/opt/parallelcluster/shared/cluster-config.yaml",
        required=False,
        help="the cluster config file, defaults to " "/opt/parallelcluster/shared/cluster-config.yaml",
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="enable verbose logging")
    parser.add_argument("--dry-run", "-d", action="store_true", help="enable dry run")
    parser.add_argument("--execute-via-cfnconfig", "-e", action="store_true", help="execute via cfnconfig")

    try:
        args = parser.parse_args()
    except SystemExit as e:
        e.code = 1
        raise e

    return args


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
        ActionRunner(conf, CustomLogger(conf)).run()

    except Exception as err:
        logging.exception(err)
        print(f"ERROR: Unexpected exception: {err}")
        raise SystemExit(1) from err

    logging.debug("Completed with success.")
    raise SystemExit(0)


if __name__ == "__main__":
    main()
