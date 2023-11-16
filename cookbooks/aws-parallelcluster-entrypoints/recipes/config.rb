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

include_recipe "aws-parallelcluster-platform::enable_chef_error_handler"

include_recipe "aws-parallelcluster-shared::setup_envars"

include_recipe 'aws-parallelcluster-platform::config'
include_recipe "aws-parallelcluster-environment::config"

# Intel HPC must be configured after the setup of the shared folder (i.e. /opt/intel)
intel_hpc 'Configure Intel HPC' do
  action :configure
end

include_recipe 'aws-parallelcluster-computefleet::config'
include_recipe 'aws-parallelcluster-slurm::config'
include_recipe 'aws-parallelcluster-awsbatch::config'

include_recipe "aws-parallelcluster-platform::log_rotation"
