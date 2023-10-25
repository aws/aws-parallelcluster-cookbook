# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: install
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

dns_domain "Install dns related packages"
mysql_client 'Install mysql client'
mysql_repo 'Configure mysql repository'
include_recipe 'aws-parallelcluster-slurm::install_jwt'
include_recipe 'aws-parallelcluster-slurm::install_pmix'
munge 'Install munge' do
  action :setup
end
include_recipe 'aws-parallelcluster-slurm::install_slurm'
