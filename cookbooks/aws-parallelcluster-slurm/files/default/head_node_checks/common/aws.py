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

import boto3
from common.constants import BOTO_CONFIG


def boto_client(service, region_name):
    """
    Return a boto3 client.

    Returning the boto3 client from a centralized place is handy for testing.

    :param service: name of the cluster.
    :param region_name: AWS region name (eg: us-east-1).
    :return: a boto3 client.
    """
    return boto3.client(service, region_name=region_name, config=BOTO_CONFIG)
