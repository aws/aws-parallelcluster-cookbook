# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

action_class do
  def pre_install
    apt_update

    bash 'install pre-req' do
      cwd Chef::Config[:file_cache_path]
      # Must install whoopsie separately before installing ubuntu-desktop to avoid whoopsie crash pop-up
      # Must purge ifupdown before creating the AMI or the instance will have an ssh failure
      # Run dpkg --configure -a if there is a `dpkg interrupted` issue when installing ubuntu-desktop
      code <<-PREREQ
        set -e
        DEBIAN_FRONTEND=noninteractive
        apt -y install whoopsie
        apt -y install ubuntu-desktop && apt -y install mesa-utils || (dpkg --configure -a && exit 1)
        apt -y purge ifupdown
        wget https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY
        gpg --import NICE-GPG-KEY
      PREREQ
      retries 10
      retry_delay 5
    end
  end

  def install_package_list(packages)
    packages.each do |package_name|
      # apt package provider cannot handle the source property, so we explicitly using the command
      execute 'apt install dcv package' do
        command "apt -y install #{package_name}"
        retries 3
        retry_delay 5
      end
    end
  end

  def package_architecture_id
    arm_instance? ? 'arm64' : 'amd64'
  end

  def dcv_package
    "nice-dcv-#{node['cluster']['dcv']['version']}-#{node['cluster']['base_os']}-#{node['cluster']['dcv']['url_architecture_id']}"
  end

  def dcv_server
    "nice-dcv-server_#{node['cluster']['dcv']['server']['version']}_#{package_architecture_id}.#{node['cluster']['base_os']}.deb"
  end

  def xdcv
    "nice-xdcv_#{node['cluster']['dcv']['xdcv']['version']}_#{package_architecture_id}.#{node['cluster']['base_os']}.deb"
  end

  def dcv_web_viewer
    "nice-dcv-web-viewer_#{node['cluster']['dcv']['web_viewer']['version']}_#{package_architecture_id}.#{node['cluster']['base_os']}.deb"
  end

  def install_dcv_gl
    dcv_gl = "#{node['cluster']['sources_dir']}/#{dcv_package}/nice-dcv-gl_#{node['cluster']['dcv']['gl']['version']}_#{package_architecture_id}.#{node['cluster']['base_os']}.deb"
    execute 'apt install dcv-gl' do
      command "apt -y install #{dcv_gl}"
    end
  end

  def optionally_disable_rnd
    # Disable RNDFILE from openssl to avoid error during certificate generation
    # See https://github.com/openssl/openssl/issues/7754#issuecomment-444063355
    execute 'No RND' do
      user 'root'
      command "sed --in-place '/RANDFILE/d' /etc/ssl/openssl.cnf"
    end
  end
end
