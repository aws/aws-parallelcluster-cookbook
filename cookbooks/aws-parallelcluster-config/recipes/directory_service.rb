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
return if node['cluster']['node_type'] == 'ComputeFleet' && node['cluster']['directory_service']['disabled_on_compute_nodes'] == 'true'

sssd_conf_path = "/etc/sssd/sssd.conf"
shared_directory_service_dir = "#{node['cluster']['shared_dir']}/directory_service"
shared_sssd_conf_path = "#{shared_directory_service_dir}/sssd.conf"

if node['cluster']['node_type'] == 'HeadNode'
  region = node['cluster']['region']
  # DomainName
  # We can assume that DomainName can only be a FQDN or the domain section in a LDAP Distinguished Name.
  # We can assume it because the CLI is in charge of validating it.
  FQDN_PATTERN = /^([a-zA-Z0-9_-]+)(\.[a-zA-Z0-9_-]+)*$/.freeze
  domain_name = node['cluster']['directory_service']['domain_name']
  ldap_search_base =
    if domain_name =~ FQDN_PATTERN
      domain_name.split('.').map { |v| "DC=#{v}" }.join(',')
    else
      domain_name
    end

  # Domain Address
  domain_addresses = node['cluster']['directory_service']['domain_addr'].split(",")
  # If a domain address does not include a protocol, ldaps is assumed for it.
  ldap_uri_components = domain_addresses.map do |domain_address|
    if URI.parse(domain_address).scheme
      domain_address
    else
      Chef::Log.info("No protocol specified for domain address #{domain_address}. Assuming ldaps.")
      "ldaps://#{domain_address}"
    end
  end

  # Password
  # The Active Directory Password can be:
  #   1. A secret in Secrets Manager, e.g. arn:aws:secretsmanager:eu-west-1:12345678910:secret:PasswordName
  #   2. A parameter in SSM, e.g. arn:aws:ssm:eu-west-1:12345678910:parameter/PasswordName
  password_secret_arn_str = node['cluster']['directory_service']['password_secret_arn']
  password_secret_arn = parse_arn(password_secret_arn_str)
  password_secret_service = password_secret_arn[:service]
  password_secret_resource = password_secret_arn[:resource]
  ldap_password =
    if password_secret_service == "secretsmanager" && password_secret_resource.start_with?("secret")
      shell_out!("aws secretsmanager get-secret-value --secret-id #{password_secret_arn_str} --region #{region} --query 'SecretString' --output text").stdout.strip
    elsif password_secret_service == "ssm" && password_secret_resource.start_with?("parameter")
      (parameter_name = password_secret_resource.split("/")[1])
      shell_out!("aws ssm get-parameter --name #{parameter_name} --region #{region} --with-decryption --query 'Parameter.Value' --output text").stdout.strip
    else
      raise "The secret #{password_secret_arn_str} is not supported"
    end

  # Head node writes the sssd.conf file and contacts the secret manager to retrieve the LDAP password.
  # Then the sssd.conf file is shared through shared_sssd_conf_path to compute nodes.
  # Only contacting the secret manager from head node avoids giving permission to compute nodes to contact the secret manager.

  # Configure SSSD domain properties
  domain_properties = {
    # Mandatory properties that must not be overridden by the user.
    'id_provider' => 'ldap',
    'ldap_schema' => 'AD',

    # Mandatory properties that are meant to be set via dedicated cluster config properties,
    # but that can also be overridden via DirectoryService/AdditionalSssdConfigs.
    'ldap_uri' => ldap_uri_components.join(','),
    'ldap_search_base' => ldap_search_base,
    'ldap_default_bind_dn' => node['cluster']['directory_service']['domain_read_only_user'],
    'ldap_default_authtok' => ldap_password,
    'ldap_tls_reqcert' => node['cluster']['directory_service']['ldap_tls_req_cert'],

    # Optional properties for which we provide a default value,
    # that are not meant to be set via dedicated cluster config properties,
    # but that can be overridden by the user via DirectoryService/AdditionalSssdConfigs.
    'cache_credentials' => 'True',
    'default_shell' => '/bin/bash',
    'fallback_homedir' => '/home/%u',
    'ldap_id_mapping' => 'True',
    'ldap_referrals' => 'False',
    'use_fully_qualified_names' => 'False',
  }

  # Optional properties that are meant to be set via dedicated cluster config properties.
  # - ldap_tls_ca_cert
  # - ldap_access_filter
  # - access_provider only if ldap_access_filter is specified

  unless node['cluster']['directory_service']['ldap_tls_ca_cert'].eql?('NONE')
    domain_properties['ldap_tls_cacert'] = node['cluster']['directory_service']['ldap_tls_ca_cert']
  end

  unless node['cluster']['directory_service']['ldap_access_filter'].eql?('NONE')
    domain_properties['access_provider'] = 'ldap'
    domain_properties['ldap_access_filter'] = node['cluster']['directory_service']['ldap_access_filter']
  end

  # Optional properties that are meant to be set via DirectoryService/AdditionalSssdConfigs
  if node['cluster']['directory_service']['additional_sssd_configs']
    domain_properties.merge!(node['cluster']['directory_service']['additional_sssd_configs'])
  end

  # Write sssd.conf file
  template sssd_conf_path do
    source 'directory_service/sssd.conf.erb'
    owner 'root'
    group 'root'
    mode '0600'
    variables(
      domain_properties: domain_properties
    )
    sensitive true
  end

  # Share the sssd.conf file to shared directory
  directory shared_directory_service_dir do
    owner 'root'
    group 'root'
    mode '0600'
    recursive true
  end

  unless node['cluster']['directory_service']['disabled_on_compute_nodes'] == 'true'
    execute 'Copy sssd.conf from head node to the shared folder' do
      user 'root'
      command "cp #{sssd_conf_path} #{shared_sssd_conf_path}"
      sensitive true
    end
  end

  bash 'Enable SSH password authentication on head node' do
    user 'root'
    code <<-AD
      sed -ri 's/\s*PasswordAuthentication\s+no$/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    AD
  end

  # Create directory for tools related to the directory service
  directory_service_scripts_path = "#{node['cluster']['scripts_dir']}/directory_service"
  directory directory_service_scripts_path do
    owner 'root'
    group 'root'
    mode '0744'
    recursive true
  end

  template "#{directory_service_scripts_path}/update_directory_service_password.sh" do
    source 'directory_service/update_directory_service_password.sh.erb'
    owner 'root'
    group 'root'
    mode '0744'
    variables(
      secret_arn: password_secret_arn_str,
      region: region,
      shared_sssd_conf_path: shared_sssd_conf_path
    )
    sensitive true
  end

  pam_services = %w(sudo su sshd)
  pam_config_dir = "/etc/pam.d"
  generate_ssh_key_path = "#{node['cluster']['scripts_dir']}/generate_ssh_key.sh"
  ssh_key_generator_pam_config_line = "session    optional     pam_exec.so log=/var/log/parallelcluster/pam_ssh_key_generator.log #{generate_ssh_key_path}"
  if node['cluster']["directory_service"]["generate_ssh_keys_for_users"] == 'true'
    template generate_ssh_key_path do
      source 'directory_service/generate_ssh_key.sh.erb'
      owner 'root'
      group 'root'
      mode '0755'
    end
    pam_services.each do |pam_service|
      pam_config_file = "#{pam_config_dir}/#{pam_service}"
      append_if_no_line "Ensure PAM service #{pam_service} is configured to call SSH key generation script" do
        path pam_config_file
        line ssh_key_generator_pam_config_line
      end
    end
  else
    # Remove script used to generate key if it exists and ensure PAM is not configured to try to call it
    file generate_ssh_key_path do
      action :delete
      only_if { ::File.exist? generate_ssh_key_path }
    end

    pam_services.each do |pam_service|
      pam_config_file = "#{pam_config_dir}/#{pam_service}"
      delete_lines "Ensure PAM service #{pam_service} is not configured to call SSH key generation script" do
        path pam_config_file
        pattern %r{session\s+optional\s+pam_exec\.so\s+log=/var/log/parallelcluster/pam_ssh_key_generator\.log}
        ignore_missing true
      end
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

system_authentication "Configure system authentication" do
  action :configure
end

# Restart modified services
%w(sssd sshd).each do |daemon|
  service daemon do
    action :restart
    sensitive true
  end
end
