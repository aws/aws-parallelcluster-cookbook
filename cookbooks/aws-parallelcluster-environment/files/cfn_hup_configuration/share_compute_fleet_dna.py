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


import configparser
import argparse
from email import message_from_string
import json
import os
import boto3
from botocore.config import Config
import yaml
import base64
import logging
from retrying import retry

COMPUTE_FLEET_SHARED_LOCATION = "/opt/parallelcluster/shared/"

COMPUTE_FLEET_SHARED_DNA_LOCATION = COMPUTE_FLEET_SHARED_LOCATION + 'dna/'

COMPUTE_FLEET_LAUNCH_TEMPLATE_CONFIG = COMPUTE_FLEET_SHARED_LOCATION + 'launch-templates-config.json'

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

def get_compute_launch_template_ids(lt_config_file_name):
    """Load launch-templates-config.json which contains ID, Version number and Logical ID of all queues in Compute Fleet's Launch Template.
    The format of launch-templates-config.json is
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
        }
     }
    """
    lt_config = None
    try:
        with open(lt_config_file_name, 'r') as file:
            lt_config = json.loads(file.read())
    except Exception as err:
        logger.warn("Unable to read %s due to %s", lt_config_file_name, err)

    return  lt_config


def share_compute_fleet_dna(args):
    """Creates all dna.json for each queue in cluster."""
    lt_config = get_compute_launch_template_ids(COMPUTE_FLEET_LAUNCH_TEMPLATE_CONFIG)
    if lt_config:
        all_queues = lt_config.get('Queues')
        for _, queues in all_queues.items():
            compute_resources = queues.get('ComputeResources')
            for _, compute_res in compute_resources.items():
                get_latest_dna_data(compute_res, COMPUTE_FLEET_SHARED_DNA_LOCATION, args)


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
def get_user_data(lt_id, lt_version, region_name):
    """
    Calls EC2 DescribeLaunchTemplateVersions API to get UserData from Launch Template specified.
    :param lt_id: Launch Template ID (eg: lt-12345678901234567)
    :param lt_version: Launch Template latest Version Number (eg: 2)
    :param region_name: AWS region name (eg: us-east-1)
    :return: User_data in MIME format
    """
    decoded_data = None
    try:
        proxy_config = parse_proxy_config()

        ec2_client = boto3.client("ec2", region_name=region_name, config=proxy_config)
        response = ec2_client.describe_launch_template_versions(
            LaunchTemplateId= lt_id,
            Versions=[
                lt_version,
            ],
        ).get('LaunchTemplateVersions')
        decoded_data = base64.b64decode(response[0]['LaunchTemplateData']['UserData'], validate=True).decode('utf-8')
    except Exception as err:
        if hasattr(err, "message"):
            err = err.message
        logger.error(
            "Unable to get UserData for launch template %s with version %s.\nException: %s",
            lt_id, lt_version, err
        )

    return decoded_data


def get_write_directives_section(user_data):
    """
    Parses MIME formatted UserData that we get from EC2 to extract write_files section from cloud-config section.
    """
    write_directives_section = None
    try:
        data = message_from_string(user_data)
        for cloud_config_section in data.walk():
            if cloud_config_section.get_content_type() == 'text/cloud-config':
                write_directives_section = yaml.safe_load(cloud_config_section._payload).get('write_files')
    except Exception as err:
        logger.error("Error occurred while parsing write_files section.\nException: %s", err)
    return write_directives_section


def write_dna_files(write_files_section, shared_storage_loc):
    """
    Writes the dna.json in shared location after extracting it from write_files section of UserData.
    :param write_files_section: Entire write_files section from UserData
    :param shared_storage_loc: Shared Storage Location of where to write dna.json
    :return: None
    """
    try:
        file_path = shared_storage_loc+"-dna.json"
        for data in write_files_section:
            if data['path'] in ['/tmp/dna.json']:
                with open(file_path,"w") as file:
                    file.write(json.dumps(json.loads(data['content']),indent=4))
    except Exception as err:
        if hasattr(err, "message"):
            err = err.message
        logger.error("Unable to write %s due to %s", file_path, err)


def get_latest_dna_data(resource, output_location, args):
    """
    Function to get latest User Data, extract relevant details and write dna.json.
    :param resource: Resource containing LT ID, Version and Logical id
    :param output_location: Shared Storage Location were we want to write dna.json
    :param args: Command Line arguments
    :rtype: None
    """
    user_data = get_user_data(resource.get('LaunchTemplate').get('Id'), resource.get('LaunchTemplate').get('Version'), args.region)
    if user_data:
        write_directives = get_write_directives_section(user_data)
        write_dna_files(write_directives, output_location+resource.get('LaunchTemplate').get("LogicalId"))


def cleanup(directory_loc):
    """Cleanup dna.json and extra.json files."""
    for f in os.listdir(directory_loc):
        f_path = os.path.join(directory_loc, f)
        try:
            if os.path.isfile(f_path):
                os.remove(f_path)
        except Exception as err:
            logger.warn(f"Unable to delete %s due to %s", f_path, err)


def _parse_cli_args():
    """Parse command line args."""
    parser = argparse.ArgumentParser(
        description="Get latest User Data from ComputeFleet Launch Templates.", exit_on_error=False
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
        "-c",
        "--cleanup",
        action="store_true",
        required=False,
        help="Cleanup DNA files created",
    )

    args = parser.parse_args()

    return args


def main():
    try:
        args = _parse_cli_args()
        if args.cleanup:
            cleanup(COMPUTE_FLEET_SHARED_DNA_LOCATION)
        else:
            share_compute_fleet_dna(args)
    except Exception as err:
        if hasattr(err, "message"):
            err = err.message
        logger.exception("Encountered exception when fetching latest dna.json for ComputeFleet, exiting gracefully: %s", err)
        raise SystemExit(0)


if __name__ == "__main__":
    main()