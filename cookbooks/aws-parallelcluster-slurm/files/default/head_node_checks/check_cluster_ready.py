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
from datetime import datetime

import click
from common.constants import CLUSTER_CONFIG_DDB_ID
from common.ddb_utils import get_cluster_config_records
from common.ec2_utils import list_cluster_instance_ids_iterator
from common.exceptions import CheckFailedError

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


BATCH_SIZE = 500

# Must match the strftime format used in dynamo.rb and helpers.rb: "%Y-%m-%dT%H:%M:%S.%3N+00:00"
TIMESTAMP_FORMAT = "%Y-%m-%dT%H:%M:%S.%f%z"


def _check_cluster_config_items(
    instance_ids: [str], items: [{}], expected_config_version: str, cutoff_time: datetime = None
):
    missing = []
    incomplete = []
    wrong = []
    wrong_tolerated = []

    if not instance_ids:
        logger.warning("No instances to check cluster config version for")
        return missing, incomplete, wrong, wrong_tolerated

    # Transform DDB items to make it easier to search.
    # Example: the original items:
    # [
    #   { "Id": { "S": "CLUSTER_CONFIG.i-123456789" },
    #     "Data": {
    #       "M": {
    #         "cluster_config_version": { "HoqyEZYBkMig3gSxaMARUv0NGcG0rrso" },
    #         "lastUpdateTime": { "2024-01-16T18:59:18.000+00:00" }
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
    #     "lastUpdateTime": { "2024-01-16T18:59:18.000+00:00" }
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

        if cluster_config_version is None:  # Incomplete records
            incomplete.append(instance_id)
            continue

        if cluster_config_version != expected_config_version:  # Wrong records
            if completed_bootstrap_after(data, cutoff_time):  # Wrong records, tolerated
                wrong_tolerated.append(instance_id)
            else:  # Wrong records, not tolerated
                wrong.append((instance_id, cluster_config_version))

    return missing, incomplete, wrong, wrong_tolerated


def completed_bootstrap_after(data: dict, cutoff_time: datetime) -> bool:
    # If no cut-off time is provided, cannot say whether the node was bootstrapped before or after the cut-off time.
    if not cutoff_time:
        return False

    # We only tolerate nodes that completed the bootstrap after the cut-off, not the update.
    # Nodes that completed the update after the cut-off are still required to apply the update.
    status = data.get("status", {}).get("S")
    if status != "DEPLOYED_BOOTSTRAP":
        return False

    # If there is no last update time, cannot say whether the node was bootstrapped before or after the cut-off time.
    last_update_time_str = data.get("lastUpdateTime", {}).get("S")
    if not last_update_time_str:
        return False

    try:
        last_update_time = datetime.strptime(last_update_time_str, TIMESTAMP_FORMAT)
        return last_update_time >= cutoff_time
    except (ValueError, TypeError):
        logger.warning(
            "Cannot parse lastUpdateTime '%s', assuming record was updated before the cut off time '%s'",
            last_update_time_str,
            cutoff_time,
        )
        return False


def check_deployed_config_version(
    cluster_name: str, table_name: str, expected_config_version: str, region: str, cutoff_time_dt: datetime = None
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
    :param cutoff_time_dt: optional UTC timestamp; nodes with wrong records that completed bootstrap
           after this time are ignored.
    :return: None
    """
    logger.info(
        "Checking that cluster configuration deployed on cluster nodes for cluster %s is %s",
        cluster_name,
        expected_config_version,
    )

    if cutoff_time_dt:
        cutoff_str = cutoff_time_dt.isoformat(timespec="milliseconds")
        logger.info("Cutoff time: %s", cutoff_str)
    else:
        cutoff_str = "None"
        logger.info("No check start time provided, all nodes with wrong config version will be reported")

    for instance_ids in list_cluster_instance_ids_iterator(
        cluster_name=cluster_name,
        node_type=["Compute", "LoginNode"],
        instance_state=["running"],
        region=region,
    ):
        n_instance_ids = len(instance_ids)

        if not n_instance_ids:
            logger.warning("Found empty batch of cluster nodes: nothing to check")
            continue

        logger.info("Found batch of %s cluster node(s): %s", n_instance_ids, instance_ids)

        items = get_cluster_config_records(table_name, instance_ids, region)
        logger.info("Retrieved %s DDB item(s):\n\t%s", len(items), "\n\t".join([str(i) for i in items]))

        missing, incomplete, wrong, wrong_tolerated = _check_cluster_config_items(
            instance_ids, items, expected_config_version, cutoff_time_dt
        )

        wrong_tolerated_label = f"wrong records tolerated, bootstrapped after cut-off time ({cutoff_str})"

        if incomplete or wrong:
            raise CheckFailedError(
                f"Check failed due to the following erroneous records "
                f"(missing records and {wrong_tolerated_label} are not counted for the failure):\n"
                f"  * missing records ({len(missing)}): {missing}\n"
                f"  * incomplete records ({len(incomplete)}): {incomplete}\n"
                f"  * wrong records ({len(wrong)}): {wrong}\n"
                f"  * {wrong_tolerated_label} ({len(wrong_tolerated)}): {wrong_tolerated}"
            )
        if missing:
            logger.warning(
                "Ignoring the following missing records due them being recently bootstrapped:\n"
                "  *  missing records (%s): %s",
                len(missing),
                missing,
            )
        if wrong_tolerated:
            logger.warning(
                "Ignoring the following nodes that completed bootstrap during the check:\n  *  %s (%s): %s",
                wrong_tolerated_label,
                len(wrong_tolerated),
                wrong_tolerated,
            )
        logger.info("Verified cluster configuration for cluster node(s) %s", instance_ids)


@click.command(help="Verify that the cluster has completed the deployment of the expected cluster configuration.")
@click.option("--cluster-name", required=True, help="Name of the cluster.")
@click.option("--table-name", required=True, help="Name of the DDB table.")
@click.option("--config-version", required=True, help="Expected cluster config version.")
@click.option("--region", required=True, help="Name of AWS region.")
@click.option(
    "--cutoff-time",
    required=False,
    default=None,
    help="Tolerance time as UTC timestamp (ISO 8601 format, e.g. '2026-03-12T21:16:11.000+00:00'). "
    "Nodes that completed bootstrap after this time are ignored.",
)
def check_cluster_ready(cluster_name: str, table_name: str, config_version: str, region: str, cutoff_time: str):
    logger.info(
        "Checking cluster readiness with arguments: "
        "cluster_name=%s, table_name=%s, config_version=%s, region=%s, cutoff_time=%s",
        cluster_name,
        table_name,
        config_version,
        region,
        cutoff_time,
    )

    cutoff_time_dt = None
    if cutoff_time:
        try:
            cutoff_time_dt = datetime.strptime(cutoff_time, TIMESTAMP_FORMAT)
        except ValueError:
            logger.warning("Cannot parse cutoff-time '%s', ignoring it", cutoff_time)

    try:
        check_deployed_config_version(cluster_name, table_name, config_version, region, cutoff_time_dt)
    except CheckFailedError as e:
        logger.error("Some cluster readiness checks failed: %s", e)
        raise e
    except Exception as e:
        logger.error("Cannot complete the cluster readiness checks due to internal errors: %s", e)
        raise e

    logger.info("All checks succeeded!")


if __name__ == "__main__":
    check_cluster_ready()  # pylint: disable=no-value-for-parameter
