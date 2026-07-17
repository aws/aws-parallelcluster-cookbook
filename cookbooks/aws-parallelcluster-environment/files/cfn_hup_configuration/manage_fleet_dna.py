# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
import base64
import configparser
import json
import logging
import os
from email import message_from_string

import boto3
import yaml
from botocore.config import Config
from retrying import retry

SHARED_LOCATION = "/opt/parallelcluster/shared/"

SHARED_DNA_LOCATION = SHARED_LOCATION + "dna/"

LAUNCH_TEMPLATE_CONFIG = SHARED_LOCATION + "launch-templates-config.json"

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def get_compute_launch_template_ids(lt_config_file_name):
    """
    Load launch-templates-config.json.

    It contains ID, Version number and Logical ID of all queues in Compute Fleet's Launch Template.
    It also contains Name and LogicalId of each LoginPools launch template (Id/Version are
    resolved at runtime by Name to avoid a CloudFormation cycle between the head node LT
    metadata and the LoginNodes nested stack).

    The format of launch-templates-config.json:
     {
        "Queues": {
            "queue1": {
                "ComputeResources": {
                    "queue1-i1": {
                        "LaunchTemplate": {
                            "Version": "1",
                            "LogicalId": "LaunchTemplate123456789012345",
                            "Id": "lt-12345678901234567"
                        }
                    }
                }
            },
            "queue2": {
                "ComputeResources": {
                    "queue2-i1": {
                        "LaunchTemplate": {
                            "Version": "1",
                            "LogicalId": "LaunchTemplate012345678901234",
                            "Id": "lt-01234567890123456"
                        }
                    }
                }
            }
        },
        "LoginPools": {
            "pool1": {
                "LaunchTemplate": {
                    "Version": "$Latest",
                    "LogicalId": "LoginNodeLaunchTemplate0123456789012345",
                    "Name": "<stack_name>-pool1"
                }
            }
        }
     }

    """
    lt_config = None
    try:
        logger.info("Getting LaunchTemplate ID and versions from %s", lt_config_file_name)
        with open(lt_config_file_name, "r", encoding="utf-8") as file:
            lt_config = json.loads(file.read())
    except Exception as err:
        logger.warning("Unable to read %s due to %s", lt_config_file_name, err)

    return lt_config


def share_compute_fleet_dna(args):
    """Create dna.json for each queue in cluster."""
    lt_config = get_compute_launch_template_ids(LAUNCH_TEMPLATE_CONFIG)
    if lt_config:
        all_queues = lt_config.get("Queues")
        for _, queues in all_queues.items():
            compute_resources = queues.get("ComputeResources")
            for _, compute_res in compute_resources.items():
                get_latest_dna_data(compute_res, SHARED_DNA_LOCATION, args)


def share_login_nodes_dna(args):
    """Create dna.json for each login pool in the cluster."""
    lt_config = get_compute_launch_template_ids(LAUNCH_TEMPLATE_CONFIG)
    if lt_config:
        for pool_name, pool in lt_config.get("LoginPools", {}).items():
            get_latest_dna_data_for_login_nodes(pool_name, pool, SHARED_DNA_LOCATION, args)


def _get_login_pool_launch_template_info(pool: dict):
    """
    Extract the (name, version, logical_id) of a LoginPool's launch template.

    :param pool: LoginPool entry from launch-templates-config.json
    :return: Tuple of (lt_name, lt_version, logical_id)
    """
    lt = pool.get("LaunchTemplate", {})
    lt_name = lt.get("Name")
    lt_version = lt.get("Version")
    lt_logical_id = lt.get("LogicalId")

    if not all([lt_name, lt_version, lt_logical_id]):
        raise RuntimeError(f"Login pool config is missing required data Name/Version/LogicalId: {pool}")

    return lt_name, lt_version, lt_logical_id


def _get_login_pool_write_directives(lt_name: str, lt_version: str, region: str):
    """
    Fetch a login pool LT's UserData by name and parse its write_files section.

    :param lt_name: Name of the login pool launch template.
    :param lt_version: Launch template version to fetch (numeric or "$Latest"/"$Default")
    :param region: AWS region
    :return: write_directives The write directives from the pool user data.
    """
    user_data = get_user_data(lt_id=None, lt_version=lt_version, region_name=region, lt_name=lt_name)

    if not user_data:
        raise RuntimeError(f"Could not fetch UserData for launch template {lt_name} with version {lt_version}")

    write_directives = get_write_directives_section(user_data)

    if not write_directives:
        raise RuntimeError(
            f"Could not extract write_files from UserData of launch template {lt_name} with version {lt_version}"
        )

    return write_directives


def get_latest_dna_data_for_login_nodes(pool_name, pool, output_location, args):
    """
    Get latest UserData for a login pool LT, extract relevant details and write dna.json.

    Equivalent to get_latest_dna_data but resolves the LT by Name. The LT version is read
    from launch-templates-config.json (falling back to "$Latest" if not present), so this
    path and wait_for_login_nodes_lt_update share a single source of truth for the version.

    :param pool_name: Name of the login pool
    :param pool: LoginPool entry from launch-templates-config.json (LaunchTemplate.Name, Version and LogicalId)
    :param output_location: Shared Storage Location were we want to write dna.json
    :param args: Command Line arguments
    :rtype: None
    """
    lt_name, lt_version, logical_id = _get_login_pool_launch_template_info(pool)
    if not lt_name or not logical_id:
        logger.warning("Skipping login pool %s: missing LaunchTemplate Name or LogicalId in config", pool_name)
        return

    write_directives = _get_login_pool_write_directives(lt_name, lt_version, args.region)
    write_dna_files(write_directives, output_location + logical_id)


# FIXME: Fix Code Duplication
def parse_proxy_config():
    config = configparser.RawConfigParser()
    config.read("/etc/boto.cfg")
    proxy_config = Config()
    if config.has_option("Boto", "proxy") and config.has_option("Boto", "proxy_port"):
        proxy = config.get("Boto", "proxy")
        proxy_port = config.get("Boto", "proxy_port")
        proxy_config = Config(proxies={"https": f"{proxy}:{proxy_port}"})
    return proxy_config


@retry(stop_max_attempt_number=5, wait_fixed=3000)
def get_user_data(lt_id, lt_version, region_name, lt_name=None):
    """
    Get UserData from a Launch Template via DescribeLaunchTemplateVersions.

    Look up the LT by either lt_id or lt_name (mutually exclusive). lt_version may be a
    numeric value or the literals "$Latest" / "$Default".
    """
    if not lt_id and not lt_name:
        raise ValueError("Either lt_id or lt_name must be provided")
    if lt_id and lt_name:
        raise ValueError("lt_id and lt_name are mutually exclusive")

    decoded_data = None
    try:
        proxy_config = parse_proxy_config()

        ec2_client = boto3.client("ec2", region_name=region_name, config=proxy_config)
        lt_selector = {"LaunchTemplateId": lt_id} if lt_id else {"LaunchTemplateName": lt_name}
        logger.info(
            "Running EC2 DescribeLaunchTemplateVersions API for %s version %s",
            lt_id or lt_name,
            lt_version,
        )
        response = ec2_client.describe_launch_template_versions(
            **lt_selector,
            Versions=[lt_version],
        ).get("LaunchTemplateVersions")
        decoded_data = base64.b64decode(response[0]["LaunchTemplateData"]["UserData"], validate=True).decode("utf-8")
    except Exception as err:
        if hasattr(err, "message"):
            err = err.message
        logger.error(
            "Unable to get UserData for launch template %s with version %s.\nException: %s",
            lt_id or lt_name,
            lt_version,
            err,
        )

    return decoded_data


def get_write_directives_section(user_data):
    """Get write_files section from cloud-config section of MIME formatted UserData."""
    write_directives_section = None
    try:
        data = message_from_string(user_data)
        logger.info("Parsing UserData to get write_files section")
        for cloud_config_section in data.walk():
            if cloud_config_section.get_content_type() == "text/cloud-config":
                write_directives_section = yaml.safe_load(cloud_config_section._payload).get("write_files")
    except Exception as err:
        logger.error("Error occurred while parsing write_files section.\nException: %s", err)
    return write_directives_section


def write_dna_files(write_files_section, shared_storage_loc):
    """
    After extracting dna.json from write_files section of UserData, write it in shared location.

    :param write_files_section: Entire write_files section from UserData
    :param shared_storage_loc: Shared Storage Location of where to write dna.json
    :return: None
    """
    try:
        file_path = shared_storage_loc + "-dna.json"
        for data in write_files_section:
            if data["path"] in ["/opt/parallelcluster/tmp/dna.json"]:
                with open(file_path, "w", encoding="utf-8") as file:
                    logger.info("Writing %s", file_path)
                    file.write(json.dumps(json.loads(data["content"]), indent=4))
    except Exception as err:
        if hasattr(err, "message"):
            err = err.message
        logger.error("Unable to write %s due to %s", file_path, err)


def get_latest_dna_data(resource, output_location, args):
    """
    Get latest User Data, extract relevant details and write dna.json.

    :param resource: Resource containing LT ID, Version and Logical id
    :param output_location: Shared Storage Location were we want to write dna.json
    :param args: Command Line arguments
    :rtype: None
    """
    user_data = get_user_data(
        resource.get("LaunchTemplate").get("Id"), resource.get("LaunchTemplate").get("Version"), args.region
    )
    if user_data:
        write_directives = get_write_directives_section(user_data)
        write_dna_files(write_directives, output_location + resource.get("LaunchTemplate").get("LogicalId"))


def cleanup(directory_loc):
    """Cleanup dna.json and extra.json files."""
    for f in os.listdir(directory_loc):
        f_path = os.path.join(directory_loc, f)
        try:
            if os.path.isfile(f_path):
                logger.info("Cleaning up %s", f_path)
                os.remove(f_path)
        except Exception as err:
            logger.warning("Unable to delete %s due to %s", f_path, err)


def wait_for_login_nodes_lt_update(expected_config_version, region):
    """Wait for all login pool LTs to have the expected cluster_config_version in their UserData.

    Reads login pool LT name and version from launch-templates-config.json, fetches the
    UserData for that version, and checks the embedded cluster_config_version. Raises
    RuntimeError if any pool does not match; the caller (Chef execute resource with retries)
    will retry.

    The launch template config is expected to always be present: if it cannot be read or
    parsed, a RuntimeError is raised. If the config is present but contains no login node
    pool, a warning is logged and the function returns without raising.
    """
    lt_config = get_compute_launch_template_ids(LAUNCH_TEMPLATE_CONFIG)
    if lt_config is None:
        # The launch template config is expected to always be written; a missing or unreadable
        # file is an error and the caller (Chef execute resource with retries) should retry.
        raise RuntimeError(f"Could not read or parse {LAUNCH_TEMPLATE_CONFIG} while waiting for login nodes LT update")

    login_pools = lt_config.get("LoginPools", {})
    if not login_pools:
        # No login node pool is configured, so there is nothing to wait for.
        logger.warning("No login node pool found in %s, nothing to wait for", LAUNCH_TEMPLATE_CONFIG)
        return

    for pool_name, pool in login_pools.items():
        logger.warning("Checking information for login nodes pool %s", pool_name)
        lt_name, lt_version, _ = _get_login_pool_launch_template_info(pool)
        write_directives = _get_login_pool_write_directives(lt_name, lt_version, region)
        actual_version = _extract_cluster_config_version(write_directives)
        if actual_version != expected_config_version:
            raise RuntimeError(
                f"Login pool {pool_name} (launch template {lt_name}) has "
                f"cluster_config_version={actual_version}, expected {expected_config_version}"
            )

        logger.info("Login pool %s has expected cluster_config_version=%s", pool_name, expected_config_version)


def _extract_cluster_config_version(write_directives):
    """Extract cluster.cluster_config_version from the dna.json entry in a write_files list."""
    for entry in write_directives or []:
        if entry.get("path") in ["/opt/parallelcluster/tmp/dna.json"]:
            try:
                dna = json.loads(entry["content"])
                return dna.get("cluster", {}).get("cluster_config_version")
            except Exception as err:  # noqa: BLE001
                logger.warning("Unable to parse dna.json from write_files entry: %s", err)
                return None
    return None


def _parse_cli_args():
    """Parse command line args."""
    parser = argparse.ArgumentParser(
        description="Get latest UserData from ComputeFleet and LoginNodes Launch Templates and "
        "share dna.json for each in shared storage.",
    )

    parser.add_argument(
        "-r",
        "--region",
        required=False,
        type=str,
        default=os.getenv("AWS_REGION", None),
        help="the cluster AWS region, defaults to AWS_REGION env variable",
    )

    parser.add_argument(
        "-c",
        "--cleanup",
        action="store_true",
        required=False,
        help="Cleanup DNA files created",
    )

    parser.add_argument(
        "--wait-login-nodes-launch-template-config-version",
        required=False,
        type=str,
        default=None,
        metavar="CLUSTER_CONFIG_VERSION",
        help="Wait for all login pool LTs to have this cluster_config_version in their UserData.",
    )

    args = parser.parse_args()

    return args


def main():
    args = _parse_cli_args()
    if args.cleanup:
        cleanup(SHARED_DNA_LOCATION)
        logger.info("All dna.json files have been removed!")
    elif args.wait_login_nodes_launch_template_config_version:
        cluster_config_version = args.wait_login_nodes_launch_template_config_version
        wait_for_login_nodes_lt_update(cluster_config_version, args.region)
        logger.info(
            "All login nodes launch templates are now aligned to the expected cluster config version %s",
            cluster_config_version,
        )
    else:
        share_compute_fleet_dna(args)
        share_login_nodes_dna(args)
        logger.info("All dna.json files have been shared!")


if __name__ == "__main__":
    main()
