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
import traceback
from typing import List

import yaml

log = logging.getLogger()


CAPACITY_TYPE_MAP = {
    "ONDEMAND": "on-demand",
    "SPOT": "spot",
    "CAPACITY_BLOCK": "capacity-block",
}


class CriticalError(Exception):
    """Critical error for the script."""

    pass


class ConfigurationFieldNotFoundError(Exception):
    """Field not found in configuration."""

    pass


def generate_fleet_config_file(output_file: str, input_file: str):
    """
    Generate configuration file used by Fleet Manager in node daemon package.

    Generate fleet-config.json
    {
        "my-queue": {
            "fleet-compute-resource": {
                "Api": "create-fleet",
                "CapacityType": "on-demand|spot|capacity-block",
                "AllocationStrategy": "lowest-price|capacity-optimized",
                "Instances": [
                    { "InstanceType": "p4d.24xlarge" }
                ],
                "MaxPrice": "",
                "Networking": {
                    "SubnetIds": ["subnet-123456"]
                },
                "CapacityReservationId": "id"
            }
            "single-compute-resource": {
                "Api": "run-instances",
                "CapacityType": "on-demand|spot|capacity-block",
                "AllocationStrategy": "lowest-price|capacity-optimized",
                "Instances": [
                    { "InstanceType": ... }
                ],
                "CapacityReservationId": "id"
            }
        }
    }
    """
    cluster_config = _load_cluster_config(input_file)
    queue_name, compute_resource_name = None, None
    try:
        fleet_config = {}
        for queue_config in cluster_config["Scheduling"]["SlurmQueues"]:
            queue_name = queue_config["Name"]

            # Retrieve capacity info from the queue_name, if there
            queue_capacity_type = CAPACITY_TYPE_MAP.get(queue_config.get("CapacityType", "ONDEMAND"))
            queue_allocation_strategy = queue_config.get("AllocationStrategy")
            queue_capacity_reservation_target = queue_config.get("CapacityReservationTarget", {})
            queue_capacity_reservation = (
                queue_capacity_reservation_target.get("CapacityReservationId")
                if queue_capacity_reservation_target
                else None
            )

            fleet_config[queue_name] = {}

            for compute_resource_config in queue_config["ComputeResources"]:
                compute_resource_name, config_for_fleet = _generate_compute_resource_fleet_config(
                    compute_resource_config=compute_resource_config,
                    queue_name=queue_name,
                    queue_allocation_strategy=queue_allocation_strategy,
                    queue_capacity_reservation=queue_capacity_reservation,
                    queue_capacity_type=queue_capacity_type,
                    queue_subnets=queue_config["Networking"]["SubnetIds"],
                )
                fleet_config[queue_name][compute_resource_name] = config_for_fleet

    except (KeyError, AttributeError) as e:
        if isinstance(e, KeyError):
            message = f"Unable to find key {e} in the configuration file."
        else:
            message = f"Error parsing configuration file. {e}. {traceback.format_exc()}."
        message += f" Queue: {queue_name}" if queue_name else ""
        log.error(message)
        raise CriticalError(message)

    log.info("Generating %s", output_file)
    with open(output_file, "w", encoding="utf-8") as output:
        output.write(json.dumps(fleet_config, indent=4))

    log.info("Finished.")


def _generate_compute_resource_fleet_config(
    compute_resource_config: dict,
    queue_name: str,
    queue_allocation_strategy: str,
    queue_capacity_reservation: str,
    queue_capacity_type: str,
    queue_subnets: List,
):
    """
    Generate compute resource config to add in the fleet-config.json, overriding values from the queue.

    CapacityReservationTarget can be specified on both queue and compute resource level.
    CapacityType and AllocationStrategy are not yet supported at compute resource level from the CLI,
    but this code is ready to use them.

    Returns compute_resource name and fleet-config section for the given compute resource.
    """
    compute_resource_name = compute_resource_config["Name"]

    try:
        capacity_type = CAPACITY_TYPE_MAP.get(compute_resource_config.get("CapacityType"), queue_capacity_type)
        config_for_fleet = {"CapacityType": capacity_type}

        capacity_reservation_target = compute_resource_config.get("CapacityReservationTarget", {})
        capacity_reservation = (
            capacity_reservation_target.get("CapacityReservationId", queue_capacity_reservation)
            if capacity_reservation_target
            else queue_capacity_reservation
        )
        if capacity_reservation:
            config_for_fleet.update({"CapacityReservationId": capacity_reservation})

        if compute_resource_config.get("Instances"):
            # multiple instance types, create-fleet api
            config_for_fleet.update(
                {
                    "Api": "create-fleet",
                    "Instances": copy.deepcopy(compute_resource_config["Instances"]),
                    "Networking": {"SubnetIds": queue_subnets},
                }
            )
            allocation_strategy = compute_resource_config.get("AllocationStrategy", queue_allocation_strategy)
            if allocation_strategy:
                config_for_fleet.update({"AllocationStrategy": allocation_strategy})
            if capacity_type == "spot" and compute_resource_config["SpotPrice"]:
                config_for_fleet.update({"MaxPrice": compute_resource_config["SpotPrice"]})

        elif compute_resource_config.get("InstanceType"):
            # single instance type, run-instances api
            config_for_fleet.update(
                {
                    "Api": "run-instances",
                    "Instances": [{"InstanceType": compute_resource_config["InstanceType"]}],
                }
            )

        else:
            raise ConfigurationFieldNotFoundError(
                "Instances or InstanceType field not found "
                f"in queue: {queue_name}, compute resource: {compute_resource_name} configuration"
            )
    except (KeyError, AttributeError) as e:
        if isinstance(e, KeyError):
            message = f"Unable to find key {e} in the configuration file."
        else:
            message = f"Error parsing configuration file. {e}. {traceback.format_exc()}."
        message += f" Queue: {queue_name}, Compute resource: {compute_resource_name}"
        log.error(message)
        raise CriticalError(message)

    return compute_resource_name, config_for_fleet


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
