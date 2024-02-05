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

import logging

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


def check_compute_nodes_config_version(cluster_name: str, table_name: str, expected_config_version: str, region: str):
    """
    Verify that every compute node in the cluster has deployed the expected config version.

    The verification is made by checking the config version reported by compute nodes on the cluster DDB table.
    A RuntimeError exception is raised if the check fails.
    The function is retried and the wait time is expected to be in the interval (cfn_hup_time, 2*cfn_hup_time),
    where cfn_hup_time is the wait time for the cfn-hup daemon (as of today it is 120 seconds).

    :param cluster_name: name of the cluster.
    :param table_name: DDB table to read the deployed config version from.
    :param expected_config_version: expected config version.
    :param region: AWS region name (eg: us-east-1).
    :return: None
    """
    logger.info(
        "Checking that cluster configuration deployed on compute nodes for cluster %s is %s",
        cluster_name,
        expected_config_version,
    )

    for instance_ids in list_cluster_instance_ids_iterator(
        cluster_name=cluster_name,
        node_type=["Compute"],
        instance_state=["running"],
        region=region,
    ):
        n_instance_ids = len(instance_ids)

        if not n_instance_ids:
            logger.warning("Found empty batch of compute nodes: nothing to check")
            continue

        logger.info("Found batch of %s compute node(s): %s", n_instance_ids, instance_ids)

        items = get_cluster_config_records(table_name, instance_ids, region)
        logger.info("Retrieved %s DDB item(s): %s", len(items), items)

        missing, incomplete, wrong = _check_cluster_config_items(instance_ids, items, expected_config_version)

        if missing or incomplete or wrong:
            raise CheckFailedError(
                f"Check failed due to the following erroneous records:\n"
                f"  * missing records ({len(missing)}): {missing}\n"
                f"  * incomplete records ({len(incomplete)}): {incomplete}\n"
                f"  * wrong records ({len(wrong)}): {wrong}"
            )
        logger.info("Verified cluster configuration for instance(s) %s", instance_ids)


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
        check_compute_nodes_config_version(cluster_name, table_name, config_version, region)
    except CheckFailedError as e:
        logger.error("Some cluster readiness checks failed: %s", e)
        raise e
    except Exception as e:
        logger.error("Cannot complete the cluster readiness checks due to internal errors: %s", e)
        raise e

    logger.info("All checks succeeded!")


if __name__ == "__main__":
    check_cluster_ready()  # pylint: disable=no-value-for-parameter
