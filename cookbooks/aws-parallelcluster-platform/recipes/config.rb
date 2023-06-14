# frozen_string_literal: true

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

include_recipe 'aws-parallelcluster-platform::openssh'
include_recipe "aws-parallelcluster-platform::sudo_config"
include_recipe 'aws-parallelcluster-platform::cluster_user'
include_recipe 'aws-parallelcluster-platform::networking'
include_recipe "aws-parallelcluster-platform::nvidia_config"
sticky_bits "setup sticky bits"
chrony 'enable Amazon Time Sync' do
  action :enable
end
include_recipe 'aws-parallelcluster-platform::dcv'
intel_hpc 'Configure Intel HPC' do
  action :configure
end
fetch_config 'Fetch and load cluster configs'
