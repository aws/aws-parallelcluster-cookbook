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

control 'efa_conflicting_packages_removed' do
  title 'Check packages conflicting with EFA are not installed'

  if os.redhat?
    openmpi_packages = %w(openmpi-devel openmpi)
  elsif os.debian?
    openmpi_packages = %w(libopenmpi-dev)
  else
    describe "unsupported OS" do
      pending "support for #{os.name}-#{os.release} needs to be implemented"
    end
  end

  openmpi_packages.each do |pkg|
    describe package(pkg) do
      it { should_not be_installed }
    end
  end
end

control 'efa_prereq_packages_installed' do
  title "EFA prereq packages are installed"

  efa_prereq_packages = %w(environment-modules)
  efa_prereq_packages.each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end
end

control 'efa_installed' do
  title 'Check EFA is installed'

  only_if { !os_properties.virtualized? }

  describe "Verify EFA Kernel module is available\n" do
    describe command("modinfo efa") do
      its('exit_status') { should eq(0) }
      its('stdout') { should match "description:\s+Elastic Fabric Adapter" }
    end
  end

  describe "Verify version of EFA\n" do
    describe file("/opt/amazon/efa_installed_packages") do
      it { should exist }
      its('content') { should match(/EFA installer version: 1.21.0/) }
    end
  end
end
