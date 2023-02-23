# frozen_string_literal: true

# Cookbook:: aws-parallelcluster
# Attributes:: test_attributes
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the 'License'). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the 'LICENSE.txt' file accompanying this file. This file is distributed on an 'AS IS' BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# These are overrides to force the system-tests to be pinned to a specific version
# of the packages that we install. DO NOT change them with the version-bump.
default['cluster']['parallelcluster-version'] = '3.0.0'
default['cluster']['parallelcluster-cookbook-version'] = '3.0.0'
default['cluster']['parallelcluster-node-version'] = '3.0.0'

# These are mock values for things that might be read from something external
# so we provide stubs here so that recipes can run successfully
default['cluster']['kernel_release'] =
  if platform?('centos')
    '3.10.0-1160.42.2.el7.x86_64'
  else
    '5.11.0-1017-aws'
  end
default['virtualized'] = 'true'

default['ec2'] = {
  ami_id: 'ami-00000000000000000',
  ami_launch_index: '0',
  ami_manifest_path: '(unknown)',
  block_device_mapping_ami: 'xvda',
  block_device_mapping_ephemeral0: 'xvdba',
  block_device_mapping_ephemeral1: 'xvdbb',
  block_device_mapping_ephemeral10: 'xvdbk',
  block_device_mapping_ephemeral11: 'xvdbl',
  block_device_mapping_ephemeral12: 'xvdbm',
  block_device_mapping_ephemeral13: 'xvdbn',
  block_device_mapping_ephemeral14: 'xvdbo',
  block_device_mapping_ephemeral15: 'xvdbp',
  block_device_mapping_ephemeral16: 'xvdbq',
  block_device_mapping_ephemeral17: 'xvdbr',
  block_device_mapping_ephemeral18: 'xvdbs',
  block_device_mapping_ephemeral19: 'xvdbt',
  block_device_mapping_ephemeral2: 'xvdbc',
  block_device_mapping_ephemeral20: 'xvdbu',
  block_device_mapping_ephemeral21: 'xvdbv',
  block_device_mapping_ephemeral22: 'xvdbw',
  block_device_mapping_ephemeral23: 'xvdbx',
  block_device_mapping_ephemeral3: 'xvdbd',
  block_device_mapping_ephemeral4: 'xvdbe',
  block_device_mapping_ephemeral5: 'xvdbf',
  block_device_mapping_ephemeral6: 'xvdbg',
  block_device_mapping_ephemeral7: 'xvdbh',
  block_device_mapping_ephemeral8: 'xvdbi',
  block_device_mapping_ephemeral9: 'xvdbj',
  block_device_mapping_root: '/dev/xvda',
  events_maintenance_history: '[]',
  events_maintenance_scheduled: '[]',
  hostname: 'ip-172-00-00-100.ec2.internal',
  iam: {
    info: {
      Code: 'Success',
      LastUpdated: '2021-09-23T18:38:46Z',
      InstanceProfileArn: 'arn:aws:iam::z000000000000:instance-profile/parallelcluster/cluster/cluster-InstanceProfileHeadNode-AAAAAAAAAAAAA',
      InstanceProfileId: 'AIAAAAAAAAAAAAAAAAAAA',
    },
    role_name: 'cluster_RoleHeadNode_AAAAAAAAAAAA',
  },
  identity_credentials_ec2_info: '{\n  \'Code\' : \'Success\',\n  \'LastUpdated\' : \'2021-09-23T18:38:43Z\',\n  \'AccountId\' : \'z000000000000\'\n}',
  instance_action: 'none',
  instance_id: 'i-00000000000000000',
  instance_life_cycle: 'on-demand',
  instance_type: 'c5.xlarge',
  local_hostname: 'ip-172-00-00-100.ec2.internal',
  local_ipv4: '172.00.00.100',
  mac: '00:de:ad:be:ef:00',
  metrics_vhostmd: '<?xml version=\'1.0\' encoding=\'UTF-8\'?>',
  network_interfaces_macs: {
    '00:de:ad:be:ef:00': {
      device_number: '0',
      interface_id: 'eni-00000000000000000',
      'ipv4-associations': {
        '127.0.0.1': '172.00.00.100',
      },
      local_hostname: 'ip-172-00-00-100.ec2.internal',
      local_ipv4s: '172.00.00.100',
      mac: '00:de:ad:be:ef:00',
      owner_id: '000000000000',
      public_hostname: 'ec2-0-00-000-000.compute-1.amazonaws.com',
      public_ipv4s: '127.0.0.1',
      security_group_ids: 'sg-00000000000000000',
      security_groups: 'cluster-HeadNodeSecurityGroup-AAAAAAAAAAAAA',
      subnet_id: 'subnet-00000000',
      subnet_ipv4_cidr_block: '172.0.0.0/20',
      vpc_id: 'vpc-28cf8c52',
      vpc_ipv4_cidr_block: '172.0.0.0/16',
      vpc_ipv4_cidr_blocks: '172.0.0.0/16',
    },
  },
  placement_availability_zone: 'us-east-1b',
  placement_availability_zone_id: 'use1-az6',
  placement_region: 'us-east-1',
  profile: 'default-hvm',
  public_hostname: 'ec2-0-00-000-000.compute-1.amazonaws.com',
  public_ipv4: '127.0.0.1',
  public_keys_0_openssh_key: 'ssh-rsa AAAA user\n',
  reservation_id: 'r-00000000000000000',
  security_groups: [
    'cluster-HeadNodeSecurityGroup-AAAAAAAAAAAAA',
  ],
  services_domain: 'amazonaws.com',
  services_partition: 'aws',
  userdata: '',
  account_id: 'z000000000000',
  availability_zone: 'us-east-1b',
  region: 'us-east-1',
}
