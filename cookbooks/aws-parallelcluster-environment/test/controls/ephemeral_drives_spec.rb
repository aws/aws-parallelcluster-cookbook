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

control 'tag:install_ephemeral_drives_logical_volumes_manager_installed' do
  title 'Check ephemeral drives management utility is installed'

  describe package('lvm2') do
    it { should be_installed }
  end
end

control 'tag:install_ephemeral_drives_script_created' do
  title 'Ephemeral drives script is copied to the target dir'

  describe file('/usr/local/sbin/setup-ephemeral-drives.sh') do
    it { should exist }
    its('mode') { should cmp '0744' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should_not be_empty }
  end
end

control 'tag:install_ephemeral_service_set_up' do
  title 'Ephemeral service is set up to run ephemeral drives script'

  describe file('/etc/systemd/system/setup-ephemeral.service') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should match 'ExecStart=/usr/local/sbin/setup-ephemeral-drives.sh' }
  end
end

control 'tag:install_ephemeral_service_after_network_config' do
  title 'Check setup-ephemeral service to have the correct After statement'
  network_target = os_properties.redhat? || os_properties.rocky? ? /^After=network-online.target/ : /^After=network.target$/
  describe file('/etc/systemd/system/setup-ephemeral.service') do
    it { should exist }
    its('content') { should match network_target }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'tag:config_ephemeral_drives_service_and_mount' do
  title 'Check ephemeral drives service is running'

  only_if { !os_properties.on_docker? }

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

    if ephemeral_devs.any? && !instance.custom_ami?
      # In custom AMIs the LVM can be already formatted and mounted on another folder (e.g. /opt/dlami/nvme)
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
