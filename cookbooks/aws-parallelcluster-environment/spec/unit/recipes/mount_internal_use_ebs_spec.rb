# frozen_string_literal: true

# Copyright:: 2024 Amazon.com, Inc. and its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe 'aws-parallelcluster-environment::mount_internal_use_ebs' do
  SHARED_DIR = "/opt/parallelcluster/shared"
  SHARED_DIR_HEAD = "/opt/parallelcluster/shared"
  SHARED_DIR_COMPUTE = "/opt/parallelcluster/shared"
  SHARED_DIR_LOGIN = "/opt/parallelcluster/shared_login"
  HEAD_NODE_PRIVATE_IP = "0.0.0.0"
  HARD_MOUNT_OPTIONS = "HARD_MOUNT_OPTIONS"

  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      %w(HeadNode ComputeFleet LoginNode).each do |node_type|
        context "on #{node_type}" do
          cached(:chef_run) do
            runner = runner(platform: platform, version: version) do |node|
              node.override['cluster']['node_type'] = node_type
              node.override['cluster']['shared_dir'] = SHARED_DIR
              node.override['cluster']['shared_dir_head'] = SHARED_DIR_HEAD
              node.override['cluster']['shared_dir_compute'] = SHARED_DIR_COMPUTE
              node.override['cluster']['shared_dir_login'] = SHARED_DIR_LOGIN
              node.override['cluster']['head_node_private_ip'] = HEAD_NODE_PRIVATE_IP
              node.override['cluster']['nfs']['hard_mount_options'] = HARD_MOUNT_OPTIONS
            end
            runner.converge(described_recipe)
          end
          cached(:node) { chef_run.node }

          case node_type
          when "HeadNode"
            it 'does not mount the internal EBS volume shared with all cluster nodes' do
              is_expected.not_to mount_volume("mount #{SHARED_DIR}")
            end
            it 'does not mount the internal EBS volume shared with login nodes' do
              is_expected.not_to mount_volume("mount #{SHARED_DIR_LOGIN}")
            end

          when "ComputeFleet"
            it 'mounts the internal EBS volume shared with all cluster nodes' do
              is_expected.to mount_volume("mount #{SHARED_DIR}").with(
                shared_dir: SHARED_DIR,
                device: "#{HEAD_NODE_PRIVATE_IP}:#{SHARED_DIR_HEAD}",
                fstype: "nfs",
                options: HARD_MOUNT_OPTIONS,
                retries: 10,
                retry_delay: 6
              )
            end

            it 'does not mount the internal EBS volume shared with login nodes' do
              is_expected.not_to mount_volume("mount #{SHARED_DIR_LOGIN}")
            end

          when "LoginNode"
            it 'mounts the internal EBS volume shared with all cluster nodes' do
              is_expected.to mount_volume("mount #{SHARED_DIR}").with(
                shared_dir: SHARED_DIR,
                device: "#{HEAD_NODE_PRIVATE_IP}:#{SHARED_DIR_HEAD}",
                fstype: "nfs",
                options: HARD_MOUNT_OPTIONS,
                retries: 10,
                retry_delay: 6
              )
            end
            it 'mounts the internal EBS volume shared with login nodes' do
              is_expected.to mount_volume("mount #{SHARED_DIR_LOGIN}").with(
                shared_dir: SHARED_DIR_LOGIN,
                device: "#{HEAD_NODE_PRIVATE_IP}:#{SHARED_DIR_LOGIN}",
                fstype: "nfs",
                options: HARD_MOUNT_OPTIONS,
                retries: 10,
                retry_delay: 6
              )
            end
          end
        end
      end
    end
  end
end
