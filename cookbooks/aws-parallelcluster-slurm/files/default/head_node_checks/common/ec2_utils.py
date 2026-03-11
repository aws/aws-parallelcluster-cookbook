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

from common.aws import boto_client
from common.constants import BOTO_PAGINATION_CONFIG, CLUSTER_NAME_TAG, NODE_TYPE_TAG
from retrying import retry


@retry(stop_max_attempt_number=5, wait_fixed=3000)
def list_cluster_instance_ids_iterator(
    cluster_name: str,
    region: str,
    instance_state: [str] = ("pending", "running", "stopping", "stopped"),
    node_type: [str] = None,
):
    """
    Generate an iterator over batch of cluster instances.

    :param cluster_name: name of the cluster.
    :param region: AWS region name (eg: us-east-1)
    :param instance_state: list of instance states to include in the filter; default is None.
    :param node_type: list of node types to include in the filter; default is None.
    :return: the iterator to iterate over batch of cluster instances.
    """
    ec2 = boto_client("ec2", region_name=region)

    filters = _get_filters_to_list_instances(cluster_name, instance_state, node_type)

    paginator = ec2.get_paginator("describe_instances")

    for page in paginator.paginate(Filters=filters, PaginationConfig=BOTO_PAGINATION_CONFIG):
        instances = []
        for reservation in page.get("Reservations", []):
            for instance in reservation.get("Instances", []):
                instances.append(instance.get("InstanceId"))
        yield instances


def _get_filters_to_list_instances(cluster_name: str, instance_state: [str] = None, node_type: [str] = None):
    """
    Generate a list of filters to be used in EC2 requests to filter cluster instances.

    :param cluster_name: name of the cluster.
    :param instance_state: list of instance states to include in the filter; default is None.
    :param node_type: list of node types to include in the filter; default is None.
    :return: the list of filters.
    """
    filters = [{"Name": f"tag:{CLUSTER_NAME_TAG}", "Values": [cluster_name]}]

    if node_type:
        filters.append({"Name": f"tag:{NODE_TYPE_TAG}", "Values": list(node_type)})

    if instance_state:
        filters.append({"Name": "instance-state-name", "Values": list(instance_state)})

    return filters


@retry(stop_max_attempt_number=5, wait_fixed=3000)
def get_asg_terminating_instance_ids(cluster_name: str, region: str) -> set:
    """
    Return instance IDs that are in ASG terminating lifecycle states.

    Instances in Terminating:Wait or Terminating:Proceed states are being terminated
    but may still appear as 'running' in EC2. These should be excluded from readiness checks.

    :param cluster_name: name of the cluster.
    :param region: AWS region name (eg: us-east-1).
    :return: set of instance IDs in terminating states.
    """
    asg = boto_client("autoscaling", region_name=region)

    terminating_ids = set()
    paginator = asg.get_paginator("describe_auto_scaling_instances")

    for page in paginator.paginate(PaginationConfig=BOTO_PAGINATION_CONFIG):
        for instance in page.get("AutoScalingInstances", []):
            # Check if instance belongs to this cluster by matching ASG name pattern
            asg_name = instance.get("AutoScalingGroupName", "")
            if cluster_name not in asg_name:
                continue

            lifecycle_state = instance.get("LifecycleState", "")
            if lifecycle_state in ("Terminating:Wait", "Terminating:Proceed"):
                terminating_ids.add(instance["InstanceId"])

    return terminating_ids
