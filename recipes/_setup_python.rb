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

pyenv_user_install 'root'

pyenv_python node['cfncluster']['python-version'] do
  user 'root'
end

pyenv_plugin 'virtualenv' do
  git_url 'https://github.com/pyenv/pyenv-virtualenv'
  user 'root'
end

pyenv_script 'pyenv virtualenv' do
    code "pyenv virtualenv #{node['cfncluster']['python-version']} #{node['cfncluster']['virtualenv']}"
    user 'root'
    not_if { ::File.exist?("#{node['cfncluster']['virtualenv_path']}/bin/activate") }
end

# Install requirements file
cookbook_file "#{node['cfncluster']['virtualenv_path']}/requirements.txt" do
  source 'requirements.txt'
  owner 'root'
  group 'root'
  mode '0755'
end

pyenv_pip "#{node['cfncluster']['virtualenv_path']}/requirements.txt" do
  virtualenv "#{node['cfncluster']['virtualenv_path']}"
  requirement true
  user 'root'
end