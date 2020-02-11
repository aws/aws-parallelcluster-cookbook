# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _setup_python
#
# Copyright 2013-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
install_pyenv "root" do
  python_version node['cfncluster']['python-version']
end

if node['platform'] == 'centos' && node['platform_version'].to_i < 7
  # CentOS 6 - install a newer version of Python using pyenv and make it globally available
  pyenv_system_install node['cfncluster']['python-version-centos6']
  pyenv_python node['cfncluster']['python-version-centos6']
  pyenv_global node['cfncluster']['python-version-centos6']
end

create_virtualenv node['cfncluster']['cookbook_virtualenv'] do
  virtualenv_path node['cfncluster']['cookbook_virtualenv_path']
  user "root"
  python_version node['cfncluster']['python-version']
  requirements_path "requirements.txt"
  not_if { ::File.exist?("#{node['cfncluster']['cookbook_virtualenv_path']}/bin/activate") }
end

create_virtualenv node['cfncluster']['node_virtualenv'] do
  virtualenv_path node['cfncluster']['node_virtualenv_path']
  user "root"
  python_version node['cfncluster']['python-version']
  not_if { ::File.exist?("#{node['cfncluster']['node_virtualenv_path']}/bin/activate") }
end
