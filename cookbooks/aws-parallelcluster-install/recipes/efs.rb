# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: efs
#
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

package_name = "amazon-efs-utils"
efs_utils_tarball = node['cluster']['efs_utils']['tarball_path']
stunnel_tarball = node['cluster']['stunnel']['tarball_path']

# Do not install efs-utils if a same or newer version is already installed.
return if Gem::Version.new(get_package_version(package_name)) >= Gem::Version.new(node['cluster']['efs_utils']['version'])

if platform?('amazon')
  # On Amazon Linux 2, amazon-efs-utils and stunnel are installed from OS repo.
  package 'amazon-efs-utils' do
    retries 3
    retry_delay 5
  end
else
  # On Ubuntu and CentOS, amazon-efs-utils and stunnel are installed from source
  # Because their OS repos do not have amazon-efs-utils and new stunnel
  # Get EFS Utils tarball
  remote_file efs_utils_tarball do
    source node['cluster']['efs_utils']['url']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(efs_utils_tarball) }
  end

  # Verify tarball
  ruby_block "verify EFS Utils checksum" do
    block do
      require 'digest'
      checksum = Digest::SHA256.file(efs_utils_tarball).hexdigest
      raise "Downloaded EFS Utils package checksum #{checksum} does not match expected checksum #{node['cluster']['efs_utils']['sha256']}" if checksum != node['cluster']['efs_utils']['sha256']
    end
  end

  # Install EFS Utils following https://docs.aws.amazon.com/efs/latest/ug/installing-amazon-efs-utils.html
  case node['platform']
  when 'centos'
    bash "install efs utils" do
      cwd node['cluster']['sources_dir']
      code <<-EFSUTILSINSTALL
        set -e
        tar xf #{efs_utils_tarball}
        cd efs-utils-#{node['cluster']['efs_utils']['version']}
        make rpm
        yum -y install ./build/#{package_name}*rpm
      EFSUTILSINSTALL
    end
  when 'ubuntu'
    bash "install efs utils" do
      cwd node['cluster']['sources_dir']
      code <<-EFSUTILSINSTALL
        set -e
        tar xf #{efs_utils_tarball}
        cd efs-utils-#{node['cluster']['efs_utils']['version']}
        ./build-deb.sh
        apt-get -y install ./build/amazon-efs-utils*deb
      EFSUTILSINSTALL
    end
  end

  # Get dependencies of stunnel
  package "Install dependencies of stunnel" do
    case node['platform']
    when 'centos'
      package_name 'tcp_wrappers-devel'
    when 'ubuntu'
      package_name 'libwrap0-dev'
    end
    retries 3
    retry_delay 5
  end

  # Get stunnel tarball
  remote_file stunnel_tarball do
    source node['cluster']['stunnel']['url']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(stunnel_tarball) }
  end

  # Verify tarball
  ruby_block "verify stunnel checksum" do
    block do
      require 'digest'
      checksum = Digest::SHA256.file(stunnel_tarball).hexdigest
      raise "Downloaded stunnel package checksum #{checksum} does not match expected checksum #{node['cluster']['stunnel']['sha256']}" if checksum != node['cluster']['stunnel']['sha256']
    end
  end
  # The installation procedure follows https://docs.aws.amazon.com/efs/latest/ug/upgrading-stunnel.html
  bash "install stunnel" do
    cwd node['cluster']['sources_dir']
    code <<-STUNNELINSTALL
      set -e
      tar xvfz #{stunnel_tarball}
      cd stunnel-#{node['cluster']['stunnel']['version']}
      ./configure
      make
      if [[ -f /bin/stunnel ]]; then
      rm /bin/stunnel
      fi
      make install
      ln -s /usr/local/bin/stunnel /bin/stunnel
    STUNNELINSTALL
  end
end
