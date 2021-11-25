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

require 'uri'

return if node['cluster']["directory_service"]["enabled"] == 'false'

sssd_conf_path = "/etc/sssd/sssd.conf"
shared_directory_service_dir = "#{node['cluster']['shared_dir']}/directory_service"
shared_sssd_conf_path = "#{shared_directory_service_dir}/sssd.conf"

if node['cluster']['node_type'] == 'HeadNode'
  # If domain_addr doesn't specify a protocol, assume it's ldaps
  unless URI.parse(node['cluster']['directory_service']['domain_addr']).scheme
    Chef::Log.info("No protocol specified in domain_addr #{node['cluster']['directory_service']['domain_addr']}. Assuming ldaps.")
    node['cluster']['directory_service']['domain_addr'] = "ldaps://#{node['cluster']['directory_service']['domain_addr']}"
  end

  # Head node writes the sssd.conf file and contacts the secret manager to retrieve the LDAP password.
  # Then the sssd.conf file is shared through shared_sssd_conf_path to compute nodes.
  # Only contacting the secret manager from head node avoids giving permission to compute nodes to contact the secret manager.

  # Write sssd.conf file
  template sssd_conf_path do
    source 'directory_service/sssd.conf.erb'
    owner 'root'
    group 'root'
    mode '0600'
    variables(ldap_default_authtok: shell_out!("aws secretsmanager get-secret-value --secret-id #{node['cluster']['directory_service']['password_secret_arn']} --region #{node['cluster']['region']} --query 'SecretString' --output text").stdout)
    sensitive true
  end

  # Share the sssd.conf file to shared directory
  directory shared_directory_service_dir do
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

  bash 'Enable SSH password authentication on head node' do
    user 'root'
    code <<-AD
      sed -ri 's/\s*PasswordAuthentication\s+no$/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    AD
  end

  if node['cluster']["directory_service"]["generate_ssh_keys_for_users"] == 'true'
    sshd_pam_config_path = '/etc/pam.d/sshd'
    generate_ssh_key_path = "#{node['cluster']['scripts_dir']}/generate_ssh_key.sh"
    ssh_key_generator_pam_config_line = "session    optional     pam_exec.so log=/var/log/parallelcluster/pam_ssh_key_generator.log #{generate_ssh_key_path}"
    template generate_ssh_key_path do
      source 'directory_service/generate_ssh_key.sh.erb'
      owner 'root'
      group 'root'
      mode '0755'
    end
    if platform_family?('debian')
      sshd_pam_config_regex = /^session.*required/
      match_to_add_line_after = :last
    else
      sshd_pam_config_regex = /^session.*include.*postlogin/
      match_to_add_line_after = :first
    end
    filter_lines 'Configure PAM sshd script to call generate SSH key script' do
      path sshd_pam_config_path
      filters(
        [
          { after: [sshd_pam_config_regex, ssh_key_generator_pam_config_line, match_to_add_line_after] },
        ]
      )
    end
  end
else
  # Compute nodes copy sssd.conf from shared dir.
  execute 'Copy sssd.conf from the shared folder to the compute node' do
    user 'root'
    command "cp #{shared_sssd_conf_path} #{sssd_conf_path}"
    sensitive true
  end
end

case node['platform_family']
when 'rhel', 'amazon'
  bash 'Configure Directory Service' do
    user 'root'
    # Tell NSS, PAM to use SSSD for system authentication and identity information
    code <<-AD
      authconfig --enablemkhomedir --enablesssdauth --enablesssd --updateall
    AD
    sensitive true
  end
when 'debian'
  bash 'Enable PAM mkhomedir module' do
    user 'root'
    code <<-AD
      pam-auth-update --enable mkhomedir
    AD
    sensitive true
  end
end

# Restart modified services
%w(sssd sshd).each do |daemon|
  service daemon do
    action :restart
    sensitive true
  end
end
