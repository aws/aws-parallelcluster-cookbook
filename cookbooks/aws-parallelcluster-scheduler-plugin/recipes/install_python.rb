# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-scheduler-plugin
# Recipe:: install_python
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
#

install_pyenv node['cluster']['scheduler_plugin']['python_version'] do
  user_only true
  user node['cluster']['scheduler_plugin']['user']
  prefix node['cluster']['scheduler_plugin']['pyenv_root']
end

activate_virtual_env node['cluster']['scheduler_plugin']['virtualenv'] do
  pyenv_path node['cluster']['scheduler_plugin']['virtualenv_path']
  user node['cluster']['scheduler_plugin']['user']
  python_version node['cluster']['scheduler_plugin']['python_version']
  not_if { ::File.exist?("#{node['cluster']['scheduler_plugin']['virtualenv_path']}/bin/activate") }
end
