# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: setup_envars
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

# PATH
# PATH envar must include a set of directories, both within the recipe context and the resulting system
path_required_directories = %w(/usr/local/sbin /usr/local/bin /sbin /bin /usr/sbin /usr/bin /opt/aws/bin)

# This block configures PATH for the recipes context
ruby_block 'Configure environment variable for recipes context: PATH' do
  block do
    path_required_directories.each do |directory|
      ENV['PATH'] = "#{ENV['PATH']}:#{directory}" unless ":#{ENV['PATH']}:".include?(":#{directory}:")
    end
  end
end

# This block configures PATH for the system
template '/etc/profile.d/path.sh' do
  source 'profile/path.sh.erb'
  cookbook 'aws-parallelcluster-shared'
  owner 'root'
  group 'root'
  mode '0755'
  variables(path_required_directories: path_required_directories)
end
