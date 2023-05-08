# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

control 'tag:config_ephemeral_drives_service_and_mount' do
  title 'Check ephemeral drives service is running'

  only_if { !os_properties.virtualized? }

  def ephemeral_mount_collide_with_shared_storage?
    %w(ebs efs fsx).each do |fs|
      if node['cluster']["#{fs}_shared_dirs"].split(',').include? node['cluster']['ephemeral_dir']
        return true
      end
    end
    false
  end

  if ephemeral_mount_collide_with_shared_storage?
    # If the ephemeral drive mount dir collide with a shared mount dir the service has to be stopped and disabled
    describe service('setup-ephemeral') do
      it { should be_installed }
      it { should_not be_enabled }
      it { should_not be_running }
    end
  else
    describe service('setup-ephemeral') do
      it { should be_installed }
      it { should be_enabled }
    end

    ephemeral_devs = instance.get_ephemeral_devs

    ephemeral_devs.each do |dev|
      describe file("/dev/#{dev}") do
        its('type') { should eq :block_device }
      end
    end

    if ephemeral_devs
      describe directory(node['cluster']['ephemeral_dir']) do
        it { should exist }
        it { should be_writable }
        it { should be_mounted }
      end
      describe mount(node['cluster']['ephemeral_dir']) do
        it { should be_mounted }
        its('device') { should eq '/dev/mapper/vg.01-lv_ephemeral' }
        its('type') { should eq 'ext4' }
        its('options') { should include 'rw' }
      end
    end
  end
end
