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

control 'tag:config_systemd_slurmd_service' do
  title 'Check the basic configuration of the systemd slurmd service'
  only_if { !os_properties.on_docker? && instance.compute_node? && node['cluster']['scheduler'] == 'slurm' }

  describe 'Check that slurmd service is defined'
  describe service('slurmd') do
    it { should be_installed }
  end

  describe 'Check slurmd systemd "after" dependencies'
  describe command('systemctl list-dependencies --after --plain slurmd.service') do
    its('stdout') { should include "munge.service" }
  end
end

control 'tag:config_systemd_slurmd_service_files' do
  title 'Check the basic configuration of the systemd slurmd service'
  only_if { !os_properties.on_docker? && instance.compute_node? && node['cluster']['scheduler'] == 'slurm' }

  describe 'Check that slurmd service file exists'
  describe file('/etc/systemd/system/slurmd.service') do
    it { should exist }
  end
end

control 'tag:config_systemd_slurmd_service_nvidia_gpu_nodes' do
  title 'Check the systemd slurmd service dependencies on NVIDIA GPU compute nodes'
  only_if { !os_properties.on_docker? && instance.compute_node? && node['cluster']['scheduler'] == 'slurm' }
  only_if { instance.graphic? && instance.nvidia_installed? }

  describe 'Check slurmd systemd "after" dependencies'
  describe command('systemctl list-dependencies --after --plain slurmd.service') do
    its('stdout') { should include "parallelcluster_nvidia.service" }
  end

  describe 'Check slurmd systemd requirement dependencies'
  describe command('systemctl list-dependencies --plain slurmd.service') do
    its('stdout') { should include "parallelcluster_nvidia.service" }
  end

  describe 'Check that slurmd systemd drop-in configuration exists'
  describe directory('/etc/systemd/system/slurmd.service.d') do
    it { should exist }
  end
  describe file('/etc/systemd/system/slurmd.service.d/slurmd_nvidia_persistenced.conf') do
    it { should exist }
  end
end
