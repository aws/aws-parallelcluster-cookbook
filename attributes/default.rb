# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Attributes:: default
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# ParallelCluster log dir
default['cluster']['log_base_dir'] = '/var/log/parallelcluster'
default['cluster']['bootstrap_error_path'] = "#{node['cluster']['log_base_dir']}/bootstrap_error_msg"

# ParallelCluster log rotation file dir
default['cluster']['pcluster_log_rotation_path'] = "/etc/logrotate.d/parallelcluster_log_rotation"

# Cluster config
default['cluster']['cluster_s3_bucket'] = nil
default['cluster']['cluster_config_s3_key'] = nil
default['cluster']['cluster_config_version'] = nil
default['cluster']['change_set_s3_key'] = nil
default['cluster']['instance_types_data_s3_key'] = nil

# Intel Packages
default['cluster']['psxe']['version'] = '2020.4-17'
default['cluster']['psxe']['noarch_packages'] = %w(intel-tbb-common-runtime intel-mkl-common-runtime intel-psxe-common-runtime
                                                   intel-ipp-common-runtime intel-ifort-common-runtime intel-icc-common-runtime
                                                   intel-daal-common-runtime intel-comp-common-runtime)
default['cluster']['psxe']['archful_packages']['i486'] = %w(intel-tbb-runtime intel-tbb-libs-runtime intel-comp-runtime
                                                            intel-daal-runtime intel-icc-runtime intel-ifort-runtime
                                                            intel-ipp-runtime intel-mkl-runtime intel-openmp-runtime)
default['cluster']['psxe']['archful_packages']['x86_64'] = node['cluster']['psxe']['archful_packages']['i486'] + %w(intel-mpi-runtime)
default['cluster']['intelhpc']['platform_name'] = value_for_platform(
  'centos' => {
    '~>7' => 'el7',
  }
)
default['cluster']['intelhpc']['packages'] = %w(intel-hpc-platform-core-intel-runtime-advisory intel-hpc-platform-compat-hpc-advisory
                                                intel-hpc-platform-core intel-hpc-platform-core-advisory intel-hpc-platform-hpc-cluster
                                                intel-hpc-platform-compat-hpc intel-hpc-platform-core-intel-runtime)
default['cluster']['intelhpc']['version'] = '2018.0-7'
default['cluster']['intelpython2']['version'] = '2019.4-088'
default['cluster']['intelpython3']['version'] = '2020.2-902'

# URLs to software packages used during install recipes
default['cluster']['slurm_plugin_dir'] = '/etc/parallelcluster/slurm_plugin'
default['cluster']['slurm']['fleet_config_path'] = "#{node['cluster']['slurm_plugin_dir']}/fleet-config.json"

# Scheduler plugin event handler
default['cluster']['scheduler_plugin']['home'] = '/home/pcluster-scheduler-plugin'
default['cluster']['scheduler_plugin']['handler_log_out'] = "#{node['cluster']['log_base_dir']}/scheduler-plugin.out.log"
default['cluster']['scheduler_plugin']['handler_log_err'] = "#{node['cluster']['log_base_dir']}/scheduler-plugin.err.log"
default['cluster']['scheduler_plugin']['shared_dir'] = "#{node['cluster']['shared_dir']}/scheduler-plugin"
default['cluster']['scheduler_plugin']['local_dir'] = "#{node['cluster']['base_dir']}/scheduler-plugin"
default['cluster']['scheduler_plugin']['handler_dir'] = "#{node['cluster']['scheduler_plugin']['local_dir']}/.configs"
default['cluster']['scheduler_plugin']['scheduler_plugin_substack_outputs_path'] = "#{node['cluster']['shared_dir']}/scheduler-plugin-substack-outputs.json"
default['cluster']['scheduler_plugin']['python_version'] = '3.9.16'
default['cluster']['scheduler_plugin']['pyenv_root'] = "#{node['cluster']['scheduler_plugin']['shared_dir']}/pyenv"
default['cluster']['scheduler_plugin']['virtualenv'] = 'scheduler_plugin_virtualenv'
default['cluster']['scheduler_plugin']['virtualenv_path'] = [
  node['cluster']['scheduler_plugin']['pyenv_root'],
  'versions',
  node['cluster']['scheduler_plugin']['python_version'],
  'envs',
  node['cluster']['scheduler_plugin']['virtualenv'],
].join('/')

# OpenSSH settings for AWS ParallelCluster instances
default['openssh']['server']['protocol'] = '2'
default['openssh']['server']['syslog_facility'] = 'AUTHPRIV'
default['openssh']['server']['permit_root_login'] = 'forced-commands-only'
default['openssh']['server']['password_authentication'] = 'no'
default['openssh']['server']['gssapi_authentication'] = 'yes'
default['openssh']['server']['gssapi_clean_up_credentials'] = 'yes'
default['openssh']['server']['ciphers'] = 'aes128-cbc,aes192-cbc,aes256-cbc,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com'
default['openssh']['server']['m_a_cs'] = 'hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256'
default['openssh']['client']['gssapi_authentication'] = 'yes'
default['openssh']['client']['match'] = 'exec "ssh_target_checker.sh %h"'
# Disable StrictHostKeyChecking for target host in the cluster VPC
default['openssh']['client']['  _strict_host_key_checking'] = 'no'
# Do not store server key in the know hosts file to avoid scaling clashing
# that is when an new host gets the same IP of a previously terminated host
default['openssh']['client']['  _user_known_hosts_file'] = '/dev/null'

# ulimit settings
default['cluster']['filehandle_limit'] = 10_000
default['cluster']['memory_limit'] = 'unlimited'

# ParallelCluster internal variables (also in /etc/parallelcluster/cfnconfig)
default['cluster']['stack_name'] = nil
default['cluster']['preinstall'] = 'NONE'
default['cluster']['preinstall_args'] = 'NONE'
default['cluster']['postinstall'] = 'NONE'
default['cluster']['postinstall_args'] = 'NONE'
default['cluster']['postupdate'] = 'NONE'
default['cluster']['postupdate_args'] = 'NONE'
default['cluster']['scheduler_queue_name'] = nil
default['cluster']['instance_slots'] = '1'
default['cluster']['ephemeral_dir'] = '/scratch'
default['cluster']['proxy'] = 'NONE'
default['cluster']['volume'] = ''

# ParallelCluster internal variables to configure active directory service
default['cluster']["directory_service"]["enabled"] = 'false'
default['cluster']["directory_service"]["domain_name"] = nil
default['cluster']["directory_service"]["domain_addr"] = nil
default['cluster']["directory_service"]["password_secret_arn"] = nil
default['cluster']["directory_service"]["domain_read_only_user"] = nil
default['cluster']["directory_service"]["ldap_tls_ca_cert"] = nil
default['cluster']["directory_service"]["ldap_tls_req_cert"] = nil
default['cluster']["directory_service"]["ldap_access_filter"] = nil
default['cluster']["directory_service"]["generate_ssh_keys_for_users"] = nil
default['cluster']['directory_service']['additional_sssd_configs'] = nil
default['cluster']['directory_service']['disabled_on_compute_nodes'] = nil

# Other ParallelCluster internal variables
default['cluster']['ddb_table'] = nil
default['cluster']['slurm_ddb_table'] = nil
default['cluster']['volume_fs_type'] = 'ext4'
default['cluster']['efs_shared_dirs'] = ''
default['cluster']['efs_fs_ids'] = ''
default['cluster']['efs_encryption_in_transits'] = ''
default['cluster']['efs_iam_authorizations'] = ''
default['cluster']['fsx_shared_dirs'] = ''
default['cluster']['fsx_fs_ids'] = ''
default['cluster']['fsx_dns_names'] = ''
default['cluster']['fsx_mount_names'] = ''
default['cluster']['fsx_fs_types'] = ''
default['cluster']['fsx_volume_junction_paths'] = ''
default['cluster']['custom_node_package'] = nil
default['cluster']['custom_awsbatchcli_package'] = nil
default['cluster']['raid_type'] = ''
default['cluster']['raid_vol_ids'] = ''
default['cluster']['use_private_hostname'] = 'false'
default['cluster']['skip_install_recipes'] = 'yes'
default['cluster']['enable_nss_slurm'] = node['cluster']['directory_service']['enabled']
default['cluster']['realmemory_to_ec2memory_ratio'] = 0.95
default['cluster']['slurm_node_reg_mem_percent'] = 75
default['cluster']['slurmdbd_response_retries'] = 30
default['cluster']['slurm_plugin_console_logging']['sample_size'] = 1
default["cluster"]["scheduler_compute_resource_name"] = nil

# Official ami build
default['cluster']['is_official_ami_build'] = false

# Additional instance types data
default['cluster']['instance_types_data'] = nil

# Compute nodes bootstrap timeout
default['cluster']['compute_node_bootstrap_timeout'] = 1800
