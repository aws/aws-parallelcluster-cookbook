#
# Cookbook Name:: cfncluster
# Recipe:: _master_sge_config
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

# Export /opt/sge
nfs_export "/opt/sge" do
  network node['cfncluster']['ec2-metadata']['vpc-ipv4-cidr-block']
  writeable true
  options ['no_root_squash']
end

# Put sge_inst in place
cookbook_file 'sge_inst.conf' do
  path '/opt/sge/sge_inst.conf'
  user 'root'
  group 'root'
  mode '0644'
end

# Run inst_sge
execute "inst_sge" do
  command './inst_sge -noremote -m -auto ./sge_inst.conf'
  cwd '/opt/sge'
  not_if { ::File.exist?('/opt/sge/default/common/cluster_name') }
end

link "/etc/profile.d/sge.sh" do
  to "/opt/sge/default/common/settings.sh"
end

link "/etc/profile.d/sge.csh" do
  to "/opt/sge/default/common/settings.csh"
end

service "sgemaster.p6444" do
  supports restart: false
  action %i[enable start]
end

bash "add_host_as_master" do
  code <<-ADDHOST
    . /opt/sge/default/common/settings.sh
    qconf -as #{node['hostname']}
  ADDHOST
end

template '/opt/cfncluster/scripts/publish_pending' do
  source 'publish_pending.sge.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

cron 'publish_pending' do
  command '/opt/cfncluster/scripts/publish_pending'
end
