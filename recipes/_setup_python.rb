#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _setup_python
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
pyenv_install "root" do
  python_version node['cfncluster']['python-version']
end

activate_virtual_env node['cfncluster']['cookbook_virtualenv'] do
  pyenv_path node['cfncluster']['cookbook_virtualenv_path']
  pyenv_user "root"
  python_version node['cfncluster']['python-version']
  requirements_path "requirements.txt"
  not_if { ::File.exist?("#{node['cfncluster']['cookbook_virtualenv_path']}/bin/activate") }
end

activate_virtual_env node['cfncluster']['node_virtualenv'] do
  pyenv_path node['cfncluster']['node_virtualenv_path']
  pyenv_user "root"
  python_version node['cfncluster']['python-version']
  not_if { ::File.exist?("#{node['cfncluster']['node_virtualenv_path']}/bin/activate") }
end