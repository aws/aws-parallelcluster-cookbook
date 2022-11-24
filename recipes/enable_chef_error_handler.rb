# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: enable_chef_error_handler
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

chef_handler 'WriteChefError::WriteChefError' do
  source "/etc/chef/cookbooks/aws-parallelcluster/files/default/event_handler/write_chef_error_handler.rb"
  supports :exception => true
  action :enable
end
