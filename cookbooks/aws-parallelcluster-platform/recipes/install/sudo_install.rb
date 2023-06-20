# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-platform
# Recipe:: sudo_install
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

package "sudo" do
  retries 3
  retry_delay 5
end

# secure_path must include the below set of directories
secure_path_required_directories = %w(/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin)
secure_path_required_directories += %w(/snap/bin) # Additional path for Debian

template '/etc/sudoers.d/99-parallelcluster-secure-path' do
  source 'sudo/99-parallelcluster-secure-path.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables(secure_path_required_directories: secure_path_required_directories)
end
