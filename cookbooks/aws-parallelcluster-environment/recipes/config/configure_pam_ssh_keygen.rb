# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-environment
# Recipe:: configure_pam_ssh_keygen
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

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
