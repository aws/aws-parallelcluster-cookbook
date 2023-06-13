# For performance, set NFS threads to min(256, max(8, num_cores * 4))
default['cluster']['nfs']['threads'] = [[node['cpu']['cores'].to_i * 4, 8].max, 256].min

# Kernel release version used to select Lustre version
default['cluster']['kernel_release'] = node['kernel']['release'] unless default['cluster'].key?('kernel_release')

# CloudWatch
default['cluster']['log_group_name'] = "NONE"

# IMDS
default['cluster']['head_node_imds_secured'] = 'true'
default['cluster']['head_node_imds_allowed_users'] = ['root', node['cluster']['cluster_admin_user'], node['cluster']['cluster_user'] ]
default['cluster']['head_node_imds_allowed_users'].append('dcv') if node['cluster']['dcv_enabled'] == 'head_node'
default['cluster']['head_node_imds_allowed_users'].append(lazy { node['cluster']['scheduler_plugin']['user'] }) if node['cluster']['scheduler'] == 'plugin'

# ParallelCluster internal variables to configure active directory service
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
default['cluster']['volume_fs_type'] = 'ext4'
default['cluster']['efs_shared_dirs'] = '/shared'
default['cluster']['efs_fs_ids'] = ''
default['cluster']['efs_encryption_in_transits'] = ''
default['cluster']['efs_iam_authorizations'] = ''
default['cluster']['fsx_shared_dirs'] = ''
default['cluster']['fsx_fs_ids'] = ''
default['cluster']['fsx_dns_names'] = ''
default['cluster']['fsx_mount_names'] = ''
default['cluster']['fsx_fs_types'] = ''
default['cluster']['fsx_volume_junction_paths'] = ''
default['cluster']['raid_type'] = ''
default['cluster']['raid_vol_ids'] = ''
default['cluster']['raid_shared_dir'] = ''
default['cluster']['ephemeral_dir'] = '/scratch'
default['cluster']['scheduler_slots'] = 'vcpus'

default['cluster']['head_node_home_path'] = '/home'
default['cluster']['shared_dir_compute'] = node['cluster']['shared_dir']
default['cluster']['shared_dir_head'] = node['cluster']['shared_dir']

default['cluster']['head_node_private_ip'] = nil
