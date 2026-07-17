# ulimit settings
default['cluster']['filehandle_limit'] = 10_000

# Default gc_thresh values for performance at scale
default['cluster']['sysctl']['ipv4']['gc_thresh1'] = 0
default['cluster']['sysctl']['ipv4']['gc_thresh2'] = 15_360
default['cluster']['sysctl']['ipv4']['gc_thresh3'] = 16_384

# ArmPL
default['conditions']['arm_pl_supported'] = arm_instance?
default['cluster']['armpl']['version'] = '26.01.1'
default['cluster']['armpl']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/armpl"

# Stunnel
default['cluster']['stunnel']['version'] = '5.78'
default['cluster']['stunnel']['sha256'] = '8727e53bb8b7528f850327a2a149158422c02183bc120d1d733cc65b1e2c349d'
default['cluster']['stunnel']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/stunnel"

# Enroot
default['cluster']['enroot']['version'] = '4.2.1'
default['cluster']['enroot']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/enroot"
default['cluster']['enroot']['caps_base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/enroot"
default['cluster']['enroot']['temporary_dir'] = '/run/enroot'
default['cluster']['enroot']['persistent_dir'] = '/var/enroot'

# NVidia
default['cluster']['nvidia']['enabled'] = 'no'
default['cluster']['nvidia']['driver_version'] = '580.126.20'
default['cluster']['nvidia']['dcgm_version'] = '4.6.0-1'

default['cluster']['nvidia']['driver_base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/nvidia_driver"
default['cluster']['nvidia']['dcgm_base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/nvidia_dcgm"
default['cluster']['nvidia']['fabricmanager']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/nvidia_fabric"

# CUDA
default['cluster']['nvidia']['cuda']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/cuda"
default['cluster']['nvidia']['cuda']['samples_base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/cuda/samples"
default['cluster']['nvidia']['cuda']['version'] = '13.0.2'
default['cluster']['nvidia']['cuda']['driver_version_suffix'] = '580.95.05'

# GDRCopy
default['cluster']['nvidia']['gdrcopy']['version'] = '2.6'
default['cluster']['nvidia']['gdrcopy']['sha256'] = 'c9eaf0593567ac5765d04c48cf7923dacb2644240b35bb5f025edb3bde1d5b4f'
default['cluster']['nvidia']['gdrcopy']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/gdr_copy/v#{node['cluster']['nvidia']['gdrcopy']['version']}.tar.gz"

# nvidia-imex
default['cluster']['nvidia']['imex']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/nvidia_imex"
default['cluster']['nvidia']['imex']['force_configuration'] = false

# NVIDIA NVLSM
default['cluster']['nvidia']['nvlsm']['enabled'] = true
default['cluster']['nvidia']['nvlsm']['version'] = '2025.03.9-1'
default['cluster']['nvidia']['nvlsm']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/nvidia_nvlsm"

# DCV
default['cluster']['dcv']['install_enabled'] = true
default['cluster']['dcv']['authenticator']['user'] = "dcvextauth"
default['cluster']['dcv']['authenticator']['user_id'] = node['cluster']['reserved_base_uid'] + 3
default['cluster']['dcv']['authenticator']['group'] = node['cluster']['dcv']['authenticator']['user']
default['cluster']['dcv']['authenticator']['group_id'] = node['cluster']['dcv']['authenticator']['user_id']
default['cluster']['dcv']['authenticator']['user_home'] = "/home/#{node['cluster']['dcv']['authenticator']['user']}"
default['cluster']['dcv']['authenticator']['certificate'] = "#{node['cluster']['etc_dir']}/ext-auth-certificate.pem"
default['cluster']['dcv']['authenticator']['private_key'] = "#{node['cluster']['etc_dir']}/ext-auth-private-key.pem"
default['cluster']['dcv']['authenticator']['virtualenv_name'] = "dcv_authenticator_virtualenv"
default['cluster']['dcv']['authenticator']['virtualenv_path'] = "#{node['cluster']['system_pyenv_root']}/versions/#{node['cluster']['python-version']}/envs/#{node['cluster']['dcv']['authenticator']['virtualenv_name']}"
default['cluster']['dcv']['version'] = '2025.0-20103'
default['cluster']['dcv']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/dcv"
default['cluster']['dcv_port'] = 8443

default['cluster']['dcv']['server']['version'] = '2025.0.20103-1'
default['cluster']['dcv']['xdcv']['version'] = '2025.0.688-1'
default['cluster']['dcv']['gl']['version'] = '2025.0.1112-1'
default['cluster']['dcv']['web_viewer']['version'] = '2025.0.20103-1'

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

# ParallelCluster log rotation file dir
default['cluster']['logrotate_conf_dir'] = "/etc/logrotate.d/"

# error handler log file
default['cluster']['bootstrap_error_path'] = "#{node['cluster']['log_base_dir']}/bootstrap_error_msg"

# Cluster config
default['cluster']['cluster_s3_bucket'] = nil
default['cluster']['cluster_config_s3_key'] = nil
default['cluster']['cluster_config_version'] = nil
default['cluster']['instance_types_data_version'] = nil
default['cluster']['change_set_s3_key'] = nil
default['cluster']['instance_types_data_s3_key'] = nil

# Intel MPI
default['cluster']['intelmpi']['version'] = '2021.18'
default['cluster']['intelmpi']['full_version'] = '2021.18.0.749'
default['cluster']['intelmpi']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/impi"
