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
from email import message_from_string
import json
import mimetypes
import os
import boto3
import yaml
import base64

SHARED_LOCATION = "/opt/parallelcluster/"

COMPUTE_FLEET_SHARED_LOCATION = SHARED_LOCATION + 'shared/'
LOGIN_POOL_SHARED_LOCATION = SHARED_LOCATION + 'shared_login_nodes/'

COMPUTE_FLEET_DNA_LOC = COMPUTE_FLEET_SHARED_LOCATION + 'dna/'
LOGIN_POOL_DNA_LOC = LOGIN_POOL_SHARED_LOCATION + 'dna/'

COMPUTE_FLEET_LAUNCH_TEMPLATE_ID = COMPUTE_FLEET_SHARED_LOCATION + 'launch-templates-config.json'

LOGIN_POOL_LAUNCH_TEMPLATE_ID = LOGIN_POOL_SHARED_LOCATION + 'launch-templates-config.json'



def get_launch_template_details(shared_storage):
    with open(shared_storage, 'r') as file:
        lt_config = json.loads(file.read())
    return  lt_config


def get_compute_launch_template_ids(args):
    lt_config = get_launch_template_details(COMPUTE_FLEET_LAUNCH_TEMPLATE_ID)
    if lt_config:
        all_queues = lt_config.get('Queues')
        for _, queues in all_queues.items():
            compute_resources = queues.get('ComputeResources')
            for _, compute_res in compute_resources.items():
                get_latest_dns_data(compute_res, COMPUTE_FLEET_DNA_LOC, args)


def get_login_pool_launch_template_ids(args):
    lt_config = get_launch_template_details(LOGIN_POOL_LAUNCH_TEMPLATE_ID)
    if lt_config:
        login_pools = lt_config.get('LoginPools')
        for _, pool in login_pools.items():
            get_latest_dns_data(pool, LOGIN_POOL_DNA_LOC, args)


def get_user_data(lt_id, lt_version, region_name):
    try:
        ec2_client = boto3.client("ec2", region_name=region_name)
        response = ec2_client.describe_launch_template_versions(
            LaunchTemplateId= lt_id,
            Versions=[
                lt_version,
            ],
        ).get('LaunchTemplateVersions')
        decoded_data = base64.b64decode(response[0]['LaunchTemplateData']['UserData'], validate=True).decode('utf-8')
        return decoded_data
    except Exception as e: # binascii.Error:
        print("Exception raised", e)


def parse_mime_user_data(user_data):
    data = message_from_string(user_data)
    for cloud_config_section in data.walk():
        if cloud_config_section.get_content_type() == 'text/cloud-config':
            write_directives_section = yaml.safe_load(cloud_config_section._payload).get('write_files')

    return write_directives_section


def write_dna_files(write_files_section, shared_storage_loc):
    for data in write_files_section:
        if data['path'] in ['/tmp/dna.json']:
            with open(shared_storage_loc+"-dna.json" ,"w") as file:
                file.write(json.dumps(json.loads(data['content']),indent=4))


def get_latest_dns_data(resource, output_location, args):
    user_data = get_user_data(resource.get('LaunchTemplate').get('Id'), resource.get('LaunchTemplate').get('Version'), args.region)
    write_directives = parse_mime_user_data(user_data)
    write_dna_files(write_directives, output_location+resource.get('LaunchTemplate').get("LogicalId"))

def cleanup(directory_loc):
    for f in os.listdir(directory_loc):
        f_path = os.path.join(directory_loc, f)
        try:
            if os.path.isfile(f_path):
                os.remove(f_path)
        except Exception as e:
            print(f"Error deleting {f_path}: {e}")

def _parse_cli_args():
    parser = argparse.ArgumentParser(
        description="Get latest User Data from Compute and Login Node Launch Templates.", exit_on_error=False
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
        default=False,
        required=False,
        help="Cleanup DNA files created",
    )

    args = parser.parse_args()

    return args


def main():
    args = _parse_cli_args()
    if args.cleanup:
        cleanup(COMPUTE_FLEET_DNA_LOC)
        cleanup(LOGIN_POOL_DNA_LOC)
    else:
        get_compute_launch_template_ids(args)
    #get_login_pool_launch_template_ids(args)


if __name__ == "__main__":
    main()