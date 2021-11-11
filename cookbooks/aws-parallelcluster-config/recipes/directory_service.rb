# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: directory_service
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

return if node['cluster']["directory_service"]["enabled"] == 'false'

directory_service_dir = "#{node['cluster']['shared_dir']}/directory_service"
sssd_conf_path = "/etc/sssd/sssd.conf"
shared_sssd_conf_path = "#{directory_service_dir}/sssd.conf"

if node['cluster']['node_type'] == 'HeadNode'
  # Head node writes the sssd.conf file and contacts the secret manager to retrieve the LDAP password.
  # Then the sssd.conf file is shared through shared_sssd_conf_path to compute nodes.
  # Only contacting the secret manager from head node avoids giving permission to compute nodes to contact the secret manager.

  # Write sssd.conf file
  template sssd_conf_path do
    source 'directory_service/sssd.conf.erb'
    owner 'root'
    group 'root'
    mode '0600'
    sensitive true
  end

  # Generate and run the script to set obfuscated password
  script_path = "/tmp/set_obfuscated_password.sh"

  template script_path do
    source 'directory_service/set_obfuscated_password.sh.erb'
    owner 'root'
    group 'root'
    mode '0700'
    sensitive true
  end

  execute 'Set obfuscated password' do
    user 'root'
    command script_path
    sensitive true
  end

  # Share the sssd.conf file to shared directory
  directory directory_service_dir do
    owner 'root'
    group 'root'
    mode '0600'
    recursive true
  end

  execute 'Copy sssd.conf from head node to the shared folder' do
    user 'root'
    command "cp #{sssd_conf_path} #{shared_sssd_conf_path}"
    sensitive true
  end
else
  # Compute nodes copy sssd.conf from shared dir.
  execute 'Copy sssd.conf from the shared folder to the compute node' do
    user 'root'
    command "cp #{shared_sssd_conf_path} #{sssd_conf_path}"
    sensitive true
  end
end

bash 'Configure Directory Service' do
  user 'root'
  # Tell NSS, PAM to use SSSD for system authentication and identity information
  # Modify SSHD config to enable password login
  code <<-AD
      authconfig --enablemkhomedir --enablesssdauth --enablesssd --updateall
      sed -ri 's/\s*PasswordAuthentication\s+no$/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  AD
  sensitive true
end

# Restart modified services
%w(sssd sshd).each do |daemon|
  service daemon do
    action :restart
    sensitive true
  end
end
