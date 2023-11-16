# frozen_string_literal: true

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

control 'install_spack_correctly_installed' do
  only_if { !os_properties.on_docker? }

  describe directory(node['cluster']['spack']['root']) do
    it { should exist }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end

  describe directory("#{node['cluster']['spack']['root']}/share/spack") do
    it { should exist }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end

  describe file('/etc/profile.d/spack.sh') do
    it { should exist }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end

  describe file("#{node['cluster']['spack']['root']}/etc/spack/compilers.yaml") do
    it { should exist }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end

  spack = "#{node['cluster']['spack']['root']}/bin/spack"
  describe "spack commands can run as cluster default user #{node['cluster']['cluster_user']}" do
    subject { bash("su - #{node['cluster']['cluster_user']} -c '#{spack} find'") }
    its('exit_status') { should eq(0) }
  end

  describe "spack config audits pass" do
    subject { bash("#{spack} audit configs") }
    its('exit_status') { should eq(0) }
  end
end

control 'install_spack_can_install_packages' do
  only_if { !os_properties.on_docker? }
  spack = "#{node['cluster']['spack']['root']}/bin/spack"

  describe "spack can install packages as cluster default user #{node['cluster']['cluster_user']}" do
    subject { bash("sudo su - #{node['cluster']['cluster_user']} -c 'sudo #{spack} install xz'") }
    its('exit_status') { should eq(0) }
  end

  describe "spack can install packages as root" do
    subject { bash("sudo su - -c '#{spack} install pkgconf'") }
    its('exit_status') { should eq(0) }
  end
end

control 'config_spack_packages_config_exist' do
  title 'Check that spack has packages.yaml'

  only_if { !os_properties.on_docker? && instance.head_node? }

  describe file("#{node['cluster']['spack']['root']}/etc/spack/packages.yaml") do
    it { should exist }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end
end
