# Copyright 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

"""Helpers for reading CloudFormation stack outputs and status."""

from datetime import datetime
from typing import Optional, Tuple

import boto3


def get_stack_output(stack_name: str, region: str, output_key: str) -> str:
    """Return the value of the ``output_key`` output of the CloudFormation stack ``stack_name``.

    Raises:
        KeyError: If the stack has no output named ``output_key``.
    """
    client = boto3.client("cloudformation", region_name=region)
    stacks = client.describe_stacks(StackName=stack_name).get("Stacks", [])
    outputs = stacks[0].get("Outputs", []) if stacks else []
    for output in outputs:
        if output.get("OutputKey") == output_key:
            return output["OutputValue"]
    raise KeyError("Stack '{}' has no output '{}'.".format(stack_name, output_key))


def get_stack_status(stack_name: str, region: str, config=None) -> Tuple[str, Optional[datetime]]:
    """Return the status of the CloudFormation stack ``stack_name`` and when it was last updated.

    The last update time falls back to the creation time for a stack that was never updated.
    """
    client = boto3.client("cloudformation", region_name=region, config=config)
    stack = client.describe_stacks(StackName=stack_name)["Stacks"][0]
    return stack["StackStatus"], stack.get("LastUpdatedTime") or stack.get("CreationTime")
