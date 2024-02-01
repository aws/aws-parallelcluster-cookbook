# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-platform
# Recipe:: update
#
# Copyright:: 2013-2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

fetch_config 'Fetch and load cluster configs' do
  update true
end

sudo_access "Update Sudo Access" if node['cluster']['scheduler'] == 'slurm'
