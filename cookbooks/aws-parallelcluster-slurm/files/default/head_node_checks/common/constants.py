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
from botocore.config import Config

# BOTO
BOTO_CONFIG = Config(retries={"max_attempts": 60})
BOTO_PAGINATION_CONFIG = {"PageSize": 100}

# TAGS
CLUSTER_NAME_TAG = "parallelcluster:cluster-name"
NODE_TYPE_TAG = "parallelcluster:node-type"

# DDB
CLUSTER_CONFIG_DDB_ID = "CLUSTER_CONFIG.{instance_id}"
