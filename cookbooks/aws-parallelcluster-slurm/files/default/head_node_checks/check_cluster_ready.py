# Copyright 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with
#  the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

import json
import logging
import os
import re

import click
from common.constants import CLUSTER_CONFIG_DDB_ID
from common.ddb_utils import get_cluster_config_records
from common.ec2_utils import list_cluster_instance_ids_iterator
from common.exceptions import CheckFailedError

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


BATCH_SIZE = 500


def _check_cluster_config_items(instance_ids: [str], items: [{}], expected_config_version: str):
    missing = []
    incomplete = []
    wrong = []

    if not instance_ids:
        logger.warning("No instances to check cluster config version for")
        return missing, incomplete, wrong

    # Transform DDB items to make it easier to search.
    # Example: the original items:
    # [
    #   { "Id": { "S": "CLUSTER_CONFIG.i-123456789" },
    #     "Data": {
    #       "M": {
    #         "cluster_config_version": { "HoqyEZYBkMig3gSxaMARUv0NGcG0rrso" },
    #         "lastUpdateTime": { "2024-01-16 18:59:18 UTC" }
    #       }
    #     }
    #   }
    # ]
    #
    # is transformed into items_by_id:
    #
    # {
    #   "CLUSTER_CONFIG.i-123456789": {
    #     "cluster_config_version": { "HoqyEZYBkMig3gSxaMARUv0NGcG0rrso" },
    #     "lastUpdateTime": { "2024-01-16 18:59:18 UTC" }
    #   }
    # }
    items_by_id = {item["Id"]["S"]: item["Data"]["M"] for item in items}

    for instance_id in instance_ids:
        key = CLUSTER_CONFIG_DDB_ID.format(instance_id=instance_id)
        data = items_by_id.get(key)
        if data is None:
            missing.append(instance_id)
            continue
        cluster_config_version = data.get("cluster_config_version", {}).get("S")
        if cluster_config_version is None:
            incomplete.append(instance_id)
            continue
        if cluster_config_version != expected_config_version:
            wrong.append((instance_id, cluster_config_version))

    return missing, incomplete, wrong


def _read_change_set(shared_dir="/opt/parallelcluster/shared"):
    """
    Read change-set.json and extract modified queue names.

    :param shared_dir: path to the shared directory containing change-set.json
    :return: Set of queue names that were modified, or None if unavailable (fallback to checking all nodes).
    """
    try:
        change_set_path = os.path.join(shared_dir, "change-set.json")
        if not os.path.exists(change_set_path):
            logger.info("change-set.json not found at %s, will check all nodes", change_set_path)
            return None

        with open(change_set_path, "r") as f:
            change_set = json.load(f)

        modified_queues = set()
        for change in change_set.get("changeSet", []):
            # Extract queue name from parameter paths like: Scheduling.SlurmQueues[queue_name].*
            # Queue names must match AWS ParallelCluster naming convention: ^[a-z][a-z0-9-]*$
            parameter = change.get("parameter", "")
            match = re.match(r"Scheduling\.SlurmQueues\[([a-z][a-z0-9-]*)\]", parameter)
            if match:
                queue_name = match.group(1)
                modified_queues.add(queue_name)
                logger.debug("Found modified queue in change-set: %s (from parameter: %s)", queue_name, parameter)

        if modified_queues:
            logger.info("Found %d modified queue(s) in change-set: %s", len(modified_queues), sorted(modified_queues))
            logger.info("Will check nodes only in modified queues")
            return modified_queues
        else:
            logger.info("No queue modifications found in change-set, will check all nodes")
            return None
    except Exception as e:
        logger.warning("Failed to parse change-set.json: %s. Will check all nodes as fallback.", e)
        return None


def check_deployed_config_version(
    cluster_name: str, table_name: str, expected_config_version: str, region: str, shared_dir="/opt/parallelcluster/shared"
):
    """
    Verify that every compute/login node in the cluster has deployed the expected config version.

    The verification is made by checking the config version reported by compute/login nodes on the cluster DDB table.
    A RuntimeError exception is raised if the check fails.
    The function is retried and the wait time is expected to be in the interval (cfn_hup_time, 2*cfn_hup_time),
    where cfn_hup_time is the wait time for the cfn-hup daemon (as of today it is 120 seconds).

    :param cluster_name: name of the cluster.
    :param table_name: DDB table to read the deployed config version from.
    :param expected_config_version: expected config version.
    :param region: AWS region name (eg: us-east-1).
    :param shared_dir: path to the shared directory containing change-set.json.
    :return: None
    """
    logger.info(
        "Checking that cluster configuration deployed on cluster nodes for cluster %s is %s",
        cluster_name,
        expected_config_version,
    )

    # Read change-set to determine which queues were modified
    modified_queues = _read_change_set(shared_dir)

    if modified_queues:
        # Only check compute nodes in modified queues
        logger.info("Checking compute nodes in modified queues: %s", modified_queues)
        for instance_ids in list_cluster_instance_ids_iterator(
            cluster_name=cluster_name,
            node_type=["Compute"],
            instance_state=["running"],
            region=region,
            queue_names=list(modified_queues),
        ):
            _check_and_verify_instances(instance_ids, table_name, expected_config_version, region)

        # Always check LoginNode separately (no queue tags)
        logger.info("Checking LoginNode instances")
        for instance_ids in list_cluster_instance_ids_iterator(
            cluster_name=cluster_name,
            node_type=["LoginNode"],
            instance_state=["running"],
            region=region,
        ):
            _check_and_verify_instances(instance_ids, table_name, expected_config_version, region)
    else:
        # Fallback: check all compute and login nodes (original behavior)
        logger.info("Checking all compute and login nodes (no queue filtering)")
        for instance_ids in list_cluster_instance_ids_iterator(
            cluster_name=cluster_name,
            node_type=["Compute", "LoginNode"],
            instance_state=["running"],
            region=region,
        ):
            _check_and_verify_instances(instance_ids, table_name, expected_config_version, region)


def _check_and_verify_instances(instance_ids: [str], table_name: str, expected_config_version: str, region: str):
    """
    Helper function to check and verify instances against the expected config version.

    :param instance_ids: list of instance IDs to check.
    :param table_name: DDB table to read the deployed config version from.
    :param expected_config_version: expected config version.
    :param region: AWS region name (eg: us-east-1).
    :return: None
    """
    n_instance_ids = len(instance_ids)

    if not n_instance_ids:
        logger.warning("Found empty batch of cluster nodes: nothing to check")
        return

    logger.info("Found batch of %s cluster node(s): %s", n_instance_ids, instance_ids)

    items = get_cluster_config_records(table_name, instance_ids, region)
    logger.info("Retrieved %s DDB item(s):\n\t%s", len(items), "\n\t".join([str(i) for i in items]))

    missing, incomplete, wrong = _check_cluster_config_items(instance_ids, items, expected_config_version)

    if incomplete or wrong:
        raise CheckFailedError(
            f"Check failed due to the following erroneous records "
            f"(missing records are not counted for the failure):\n"
            f"  * missing records ({len(missing)}): {missing}\n"
            f"  * incomplete records ({len(incomplete)}): {incomplete}\n"
            f"  * wrong records ({len(wrong)}): {wrong}"
        )
    if missing:
        logger.warning(
            "Ignoring the following missing records due them being recently bootstrapped:\n"
            "  *  missing records (%s): %s",
            len(missing),
            missing,
        )
    logger.info("Verified cluster configuration for cluster node(s) %s", instance_ids)


@click.command(help="Verify that the cluster has completed the deployment of the expected cluster configuration.")
@click.option("--cluster-name", required=True, help="Name of the cluster.")
@click.option("--table-name", required=True, help="Name of the DDB table.")
@click.option("--config-version", required=True, help="Expected cluster config version.")
@click.option("--region", required=True, help="Name of AWS region.")
def check_cluster_ready(cluster_name: str, table_name: str, config_version: str, region: str):
    logger.info(
        "Checking cluster readiness with arguments: cluster_name=%s, table_name=%s, config_version=%s, region=%s",
        cluster_name,
        table_name,
        config_version,
        region,
    )

    try:
        check_deployed_config_version(cluster_name, table_name, config_version, region)
    except CheckFailedError as e:
        logger.error("Some cluster readiness checks failed: %s", e)
        raise e
    except Exception as e:
        logger.error("Cannot complete the cluster readiness checks due to internal errors: %s", e)
        raise e

    logger.info("All checks succeeded!")


if __name__ == "__main__":
    check_cluster_ready()  # pylint: disable=no-value-for-parameter
