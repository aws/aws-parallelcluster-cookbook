# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

node.default['cluster']['slurm']['install_dir'] = '/opt/slurm'
node.default['cluster']['slurm']['user'] = 'slurm'
node.default['cluster']['slurm']['group'] = 'slurm'
node.default['cluster']['scripts_dir'] = '/opt/parallelcluster/scripts'
node.default['cluster']['region'] = node['region']
node.default['cluster']['slurmdbd_response_retries'] = 30
# TODO: attributes for stack name

include_recipe "aws-parallelcluster-slurm::config_slurm_accounting"

# TODO: modify logic in config_slurm_accounting or create a new recipe for external slurmdbd
#   to use parameter in dna.json instead of digging ARN from config
