# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.
import argparse
import copy
import json
import logging

import yaml

log = logging.getLogger()


class CriticalError(Exception):
    """Critical error for the script."""

    pass


def generate_fleet_config_file(output_file, input_file):
    """
    Generate configuration file used by Fleet Manager in node daemon package.

    Generate fleet-config.json
    {
        "my-queue": {
            "fleet-compute-resource": {
                "Api": "create-fleet",
                "CapacityType": "on-demand|spot",
                "AllocationStrategy": "lowest-price"
                "Instances": [
                    { "InstanceType": ... }
                ],
                "MaxPrice": ...
                "Networking": {
                    "SubnetIds": [...]
                }
            }
            "single-compute-resource": {
                "Api": "run-instances",
                "Instances": [
                    { "InstanceType": ... }
                ],
            }
        }
    }
    """
    cluster_config = _load_cluster_config(input_file)
    queue, compute_resource = None, None
    try:
        fleet_config = {}
        for queue_config in cluster_config["Scheduling"]["SlurmQueues"]:
            queue = queue_config["Name"]
            capacity_type = "on-demand" if queue_config["CapacityType"] == "ONDEMAND" else "spot"
            allocation_strategy = queue_config.get("AllocationStrategy", "lowest-price")
            fleet_config[queue] = {}

            for compute_resource_config in queue_config["ComputeResources"]:
                compute_resource = compute_resource_config["Name"]
                fleet_config[queue][compute_resource] = {}

                if compute_resource_config.get("Instances"):
                    fleet_config[queue][compute_resource] = {
                        "Api": "create-fleet",
                        "CapacityType": capacity_type,
                        "AllocationStrategy": allocation_strategy,
                        "Instances": copy.deepcopy(compute_resource_config["Instances"]),
                    }
                    if capacity_type == "spot" and compute_resource_config["SpotPrice"]:
                        fleet_config[queue][compute_resource]["MaxPrice"] = compute_resource_config["SpotPrice"]
                    fleet_config[queue][compute_resource]["Networking"] = {
                        "SubnetIds": queue_config["Networking"]["SubnetIds"]
                    }

                elif compute_resource_config.get("InstanceType"):
                    fleet_config[queue][compute_resource] = {
                        "Api": "run-instances",
                        "Instances": [{"InstanceType": compute_resource_config["InstanceType"]}],
                    }

                else:
                    raise Exception(
                        "Instances or InstanceType field not found "
                        f"in queue: {queue}, compute resource: {compute_resource} configuration"
                    )
    except KeyError as e:
        message = f"Unable to find key {e} in the configuration"
        message += f" of queue: {queue}" if queue else " file"
        message += f", compute resource: {compute_resource}" if compute_resource else ""

        log.error(message)
        raise CriticalError(message)

    log.info("Generating %s", output_file)
    with open(output_file, "w", encoding="utf-8") as output:
        output.write(json.dumps(fleet_config, indent=4))

    log.info("Finished.")


def _load_cluster_config(input_file_path):
    """Load cluster config file."""
    with open(input_file_path, encoding="utf-8") as input_file:
        return yaml.load(input_file, Loader=yaml.SafeLoader)


def main():
    try:
        logging.basicConfig(
            level=logging.INFO, format="%(asctime)s - [%(name)s:%(funcName)s] - %(levelname)s - %(message)s"
        )
        log.info("Running ParallelCluster Fleet Config Generator")
        parser = argparse.ArgumentParser(description="Take in fleet configuration generator related parameters")
        parser.add_argument("--output-file", help="The output file for generated json fleet config", required=True)
        parser.add_argument(
            "--input-file",
            help="Yaml file containing pcluster CLI configuration file with default values",
            required=True,
        )
        args = parser.parse_args()
        generate_fleet_config_file(args.output_file, args.input_file)
    except Exception as e:
        log.exception("Failed to generate Fleet configuration, exception: %s", e)
        raise


if __name__ == "__main__":
    main()
