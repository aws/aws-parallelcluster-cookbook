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

from common.aws import boto_client
from common.constants import CLUSTER_CONFIG_DDB_ID
from retrying import retry

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


@retry(stop_max_attempt_number=5, wait_fixed=3000)
def get_cluster_config_records(table_name: str, instance_ids: [str], region: str):
    ddb = boto_client("dynamodb", region_name=region)

    if not instance_ids:
        logger.warning("No instances to retrieve cluster config records for")
        return []

    item_ids = [CLUSTER_CONFIG_DDB_ID.format(instance_id=instance_id) for instance_id in instance_ids]
    requested_keys = [{"Id": {"S": item_id}} for item_id in item_ids]

    try:
        response = ddb.batch_get_item(RequestItems={table_name: {"Keys": requested_keys}})
        items = response.get("Responses", {}).get(table_name, [])
    except Exception as e:
        raise RuntimeError(f"Cannot read config versions due to DDB error: {e}")

    return items
