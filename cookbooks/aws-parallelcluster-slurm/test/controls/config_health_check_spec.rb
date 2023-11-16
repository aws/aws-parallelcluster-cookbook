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

control 'health_check_configured' do
  title 'Check health check setup is configured'
  slurm_install_dir = "/opt/slurm"

  describe file("#{slurm_install_dir}/etc/pcluster/.slurm_plugin/scripts/health_check_manager.py") do
    it { should exist }
  end
  describe file("#{slurm_install_dir}/etc/pcluster/.slurm_plugin/scripts/logging/health_check_manager_logging.conf") do
    it { should exist }
  end
  describe file("#{slurm_install_dir}/etc/pcluster/.slurm_plugin/scripts/conf/health_check_manager.conf") do
    it { should exist }
  end
  describe file("#{slurm_install_dir}/etc/pcluster/.slurm_plugin/scripts/health_checks/gpu_health_check.sh") do
    it { should exist }
    its('mode') { should cmp '0755' }
  end
  describe file("#{slurm_install_dir}/etc/pcluster/.slurm_plugin/scripts/prolog.d/90_pcluster_health_check_manager") do
    it { should exist }
    its('mode') { should cmp '0755' }
  end
  describe file("#{slurm_install_dir}/etc/pcluster/.slurm_plugin/scripts/epilog.d/90_pcluster_noop") do
    it { should exist }
    its('mode') { should cmp '0755' }
  end
  describe file("#{slurm_install_dir}/etc/scripts/prolog.d/90_pcluster_health_check_manager") do
    it { should be_symlink }
    it { should be_linked_to "#{slurm_install_dir}/etc/pcluster/.slurm_plugin/scripts/prolog.d/90_pcluster_health_check_manager" }
  end
  describe file("#{slurm_install_dir}/etc/scripts/epilog.d/90_pcluster_noop") do
    it { should be_symlink }
    it { should be_linked_to "#{slurm_install_dir}/etc/pcluster/.slurm_plugin/scripts/epilog.d/90_pcluster_noop" }
  end
end

control 'tag:config_gpu_health_check_execution' do
  # execute gpu_health_check into head since it's not present in kitchen compute instance
  only_if { instance.head_node? && node['cluster']['scheduler'] == 'slurm' }
  title 'Check GPU health check execution'
  slurm_install_dir = "/opt/slurm"

  if instance.graphic?
    if instance.dcgmi_gpu_accel_supported?
      if (os_properties.arm? && (os_properties.centos7? || os_properties.alinux2?)) || (os_properties.alinux2? && (node['cluster']['nvidia']['enabled'] == 'no' || node['cluster']['nvidia']['enabled'] == false))
        describe command("#{slurm_install_dir}/etc/pcluster/.slurm_plugin/scripts/health_checks/gpu_health_check.sh") do
          its('exit_status') { should eq 0 }
          its('stdout') { should match /The GPU Health Check has been executed but the NVIDIA DCGM Diagnostic tool is not available in this system/ }
        end
      else
        describe command("#{slurm_install_dir}/etc/pcluster/.slurm_plugin/scripts/health_checks/gpu_health_check.sh") do
          its('exit_status') { should eq 0 }
          its('stdout') { should match /The GPU Health Check succeeded/ }
        end
      end
    else
      describe command("#{slurm_install_dir}/etc/pcluster/.slurm_plugin/scripts/health_checks/gpu_health_check.sh") do
        its('exit_status') { should eq 0 }
        its('stdout') { should match /The GPU Health Check is running in a NVIDIA GPU not supported by DCGM Diagnostic tool/ }
      end
    end
  else
    describe command("#{slurm_install_dir}/etc/pcluster/.slurm_plugin/scripts/health_checks/gpu_health_check.sh") do
      its('exit_status') { should eq 0 }
      its('stdout') { should match /The GPU Health Check is running in an instance without a supported GPU/ }
    end
  end
end
