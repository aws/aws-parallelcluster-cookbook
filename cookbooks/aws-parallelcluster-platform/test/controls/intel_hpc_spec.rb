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

control 'tag:install_intel_hpc_dependencies_downloaded' do
  title 'Checks Intel HPC dependencies have been downloaded'

  only_if { os_properties.centos7? && !os_properties.arm? }

  dependencies = %w(compat-libstdc++-33 nscd nss-pam-ldapd openssl098e)
  dependencies.each do |package|
    # The rpm can be in the sources_dir folder or already installed as dependency of other packages
    describe command("ls #{node['cluster']['sources_dir']}/#{package}*.rpm || rpm -qa #{package}* | grep #{package}") do
      its('exit_status') { should eq 0 }
    end
  end
end

control 'tag:config_intel_hpc_enough_space_on_root_volume' do
  only_if { !os_properties.on_docker? && !instance.custom_ami? }

  describe 'at least 10 GB of free space on root volume' do
    subject { bash("sudo -u #{node['cluster']['cluster_user']} df --block-size GB --output=avail / | tail -n1 | cut -d G -f1") }
    its('stdout') { should cmp >= '10' }
  end
end

control 'tag:config_intel_hpc_configured' do
  title 'Checks Intel HPC packages have been installed'

  only_if { !os_properties.on_docker? }
  only_if { os_properties.centos7? && !os_properties.arm? && node['cluster']['enable_intel_hpc_platform'] == 'true' }

  # Verify non-intel dependencies are installed
  dependencies = %w(compat-libstdc++-33 nscd nss-pam-ldapd openssl098e)
  dependencies.each do |package|
    describe package(package) do
      it { should be_installed }
    end
  end

  # Verify shared folder exists
  describe directory('/opt/intel/rpms') do
    it { should exist }
  end

  # Verify Intel HPC Platform packages
  node['cluster']['intelhpc']['packages'].each do |package_name|
    package_basename = "#{package_name}-#{node['cluster']['intelhpc']['version']}.el7.x86_64"
    describe package(package_basename) do
      it { should be_installed }
    end
  end

  describe directory("#{node['cluster']['sources_dir']}/intel/psxe") do
    it { should exist }
  end

  # Verify non-architecture-specific packages.
  node['cluster']['psxe']['noarch_packages'].each do |psxe_noarch_package|
    package_basename = "#{psxe_noarch_package}-#{node['cluster']['psxe']['version']}.noarch"
    describe package(package_basename) do
      it { should be_installed }
    end
  end

  # Verify PSXE runtime packages and dependencies for 32- and 64-bit Intel compatible processors
  %w(i486 x86_64).each do |intel_architecture|
    package_basename = "intel-psxe-runtime-#{node['cluster']['psxe']['version']}.#{intel_architecture}"
    describe package(package_basename) do
      it { should be_installed }
    end

    node['cluster']['psxe']['archful_packages'][intel_architecture].each do |psxe_archful_package|
      num_bits_for_arch = if intel_architecture == 'i486'
                            '32'
                          else
                            '64'
                          end
      package_basename = "#{psxe_archful_package}-#{num_bits_for_arch}bit-#{node['cluster']['psxe']['version']}.#{intel_architecture}"
      describe package(package_basename) do
        it { should be_installed }
      end
    end
  end

  describe file("/etc/intel-hpc-platform-release") do
    it { should exist }
  end

  # Verify Intel Python
  modulefile_dir = "/usr/share/Modules/modulefiles"

  %w(2 3).each do |python_version|
    package_version = node['cluster']["intelpython#{python_version}"]['version']
    package_basename = "intelpython#{python_version}-#{package_version}.x86_64"
    describe package(package_basename) do
      it { should be_installed }
    end

    describe file("/opt/intel/intelpython#{python_version}") do
      it { should exist }
    end

    describe file("#{modulefile_dir}/intelpython/#{python_version}") do
      it { should exist }
      its('owner') { should eq 'root' }
      its('group') { should eq 'root' }
      its('mode') { should cmp '0755' }
    end
  end

  describe directory("#{modulefile_dir}/intelpython") do
    it { should exist }
  end

  # Intel optimized math kernel library module file
  describe file("#{modulefile_dir}/intelmkl") do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end

  # Intel PSXE module file
  describe file("#{modulefile_dir}/intelpsxe") do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end
end

control 'tag:intel_one_api_toolkits_configured' do
  # TODO: Enable this test in daily run. This test requires larger root volume size.
  # TODO: After increasing the root volume size, config_intel_hpc_enough_space_on_root_volume needs to be ajusted.
  title 'Checks Intel OneApi Toolkits have been installed'

  only_if { !os_properties.on_docker? }
  only_if { !os_properties.centos7? && !os_properties.arm? }

  intel_directory = "/opt/intel"

  if node['cluster']['install_intel_base_toolkit'] == 'true'
    %w(advisor ccl compiler dal dnnl dpl ipp ippcp mkl vtune).each do |software|
      describe directory("#{intel_directory}/#{software}") do
        it { should exist }
      end
    end
  end

  modulefile_dir = "/usr/share/Modules/modulefiles"
  # Intel PSXE module file
  describe file("#{modulefile_dir}/intel") do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end
end
