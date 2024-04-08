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

control 'tag:install_slurm_dependencies_installed' do
  title "Slurm dependencies are installed"

  def lua_devel_package
    if os.debian?
      'liblua5.3-dev'
    elsif os_properties.alinux2?
      'lua53-devel'
    else
      'lua-devel'
    end
  end

  packages = []
  if os.redhat?
    if os_properties.alinux2? || os_properties.centos7?
      # Skipping redhat on docker since ubi-appstream repo is not aligned with the main repo
      packages.concat %w(json-c-devel http-parser-devel perl-Switch) unless os_properties.redhat_on_docker?
    elsif os_properties.alinux2023?
      packages.concat %w(json-c-devel perl-Switch perl dbus-devel) unless os_properties.redhat_on_docker?
    else
      packages.concat %w(json-c-devel http-parser-devel perl dbus-devel) unless os_properties.redhat_on_docker?
    end
  elsif os.debian?
    packages.concat %w(libjson-c-dev libhttp-parser-dev libswitch-perl)
  else
    describe "unsupported OS" do
      pending "support for #{os.name}-#{os.release} needs to be implemented"
    end
  end

  packages.append(lua_devel_package()) unless os_properties.redhat_on_docker?
  packages.each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end
end
