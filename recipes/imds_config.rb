# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: imds_config
#
# Copyright 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

if node['cluster']['node_type'] == 'HeadNode' && node['cluster']['scheduler'] == 'slurm'

  directory "#{node['cluster']['scripts_dir']}/imds" do
    owner 'root'
    group 'root'
    mode '0744'
    recursive true
  end

  imds_access_script = "#{node['cluster']['scripts_dir']}/imds/imds-access.sh"

  cookbook_file imds_access_script do
    source 'imds/imds-access.sh'
    owner 'root'
    group 'root'
    mode '0744'
  end

  case node['cluster']['head_node_imds_secured']
  when 'true'
    imds_allowed_users = node['cluster']['head_node_imds_allowed_users'].join(',')
    execute 'IMDS lockdown enable' do
      command "bash #{imds_access_script} --flush && bash #{imds_access_script} --allow #{imds_allowed_users}"
      user 'root'
    end
  when 'false'
    execute 'IMDS lockdown disable' do
      command "bash #{imds_access_script} --flush"
      user 'root'
    end
  else
    raise "head_node_imds_secured must be 'true' or 'false', but got #{node['cluster']['head_node_imds_secured']}"
  end
end
