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

unified_mode true
default_action :setup

action_class do
  # Utility function to install a list of packages
  def install_package_list(packages)
    packages.each do |package_name|
      package package_name do
        action :install
        source package_name
      end
    end
  end

  # Function to install and activate a Python virtual env to run the the External authenticator daemon
  def install_ext_auth_virtual_env
    return if ::File.exist?("#{node['cluster']['dcv']['authenticator']['virtualenv_path']}/bin/activate")

    install_pyenv node['cluster']['python-version'] do
      prefix node['cluster']['system_pyenv_root']
    end
    activate_virtual_env node['cluster']['dcv']['authenticator']['virtualenv'] do
      pyenv_path node['cluster']['dcv']['authenticator']['virtualenv_path']
      python_version node['cluster']['python-version']
    end
  end

  # Function to disable lock screen since default EC2 users don't have a password
  def disable_lock_screen
    # Override default GSettings to disable lock screen for all the users
    cookbook_file "/usr/share/glib-2.0/schemas/10_org.gnome.desktop.screensaver.gschema.override" do
      source 'dcv/10_org.gnome.desktop.screensaver.gschema.override'
      owner 'root'
      group 'root'
      mode '0755'
    end

    # compile gsettings schemas
    execute 'Compile gsettings schema' do
      command "glib-compile-schemas /usr/share/glib-2.0/schemas/"
    end
  end

  def dcv_url
    "https://d1uj6qtbmh3dt5.cloudfront.net/2022.2/Servers/#{dcv_package}.tgz"
  end

  def post_install
    # empty by default
  end
end

action :setup do
  return if ::File.exist?("/etc/dcv/dcv.conf")
  return if redhat_ubi?

  # Install pcluster_dcv_connect.sh script in all the OSes to use it for error handling
  cookbook_file "#{node['cluster']['scripts_dir']}/pcluster_dcv_connect.sh" do
    source 'dcv/pcluster_dcv_connect.sh'
    owner 'root'
    group 'root'
    mode '0755'
    action :create_if_missing
  end

  if node['conditions']['dcv_supported']
    # Setup dcv authenticator group
    group node['cluster']['dcv']['authenticator']['group'] do
      comment 'NICE DCV External Authenticator group'
      gid node['cluster']['dcv']['authenticator']['group_id']
      system true
    end

    # Setup dcv authenticator user
    user node['cluster']['dcv']['authenticator']['user'] do
      comment 'NICE DCV External Authenticator user'
      uid node['cluster']['dcv']['authenticator']['user_id']
      gid node['cluster']['dcv']['authenticator']['group_id']
      # home is mounted from the head node
      manage_home true
      home node['cluster']['dcv']['authenticator']['user_home']
      system true
      shell '/bin/bash'
    end

    dcv_tarball = "#{node['cluster']['sources_dir']}/dcv-#{node['cluster']['dcv']['version']}.tgz"

    pre_install

    disable_lock_screen

    # Extract DCV packages
    unless ::File.exist?(dcv_tarball)
      remote_file dcv_tarball do
        source dcv_url
        mode '0644'
        retries 3
        retry_delay 5
      end

      # Verify checksum of dcv package
      ruby_block "verify dcv checksum" do
        block do
          require 'digest'
          checksum = Digest::SHA256.file(dcv_tarball).hexdigest
          raise "Downloaded DCV package checksum #{checksum} does not match expected checksum #{node['cluster']['dcv']['package']['sha256sum']}" if checksum != dcv_sha256sum
        end
      end

      bash 'extract dcv packages' do
        cwd node['cluster']['sources_dir']
        code "tar -xvzf #{dcv_tarball}"
      end
    end

    # Install server, xdcv and web-viewer packages
    dcv_packages = %W(#{dcv_server} #{xdcv} #{dcv_web_viewer})
    dcv_packages_path = "#{node['cluster']['sources_dir']}/#{dcv_package}/"
    # Rewrite dcv_packages object by cycling each package file name and appending the path to them
    dcv_packages.map! { |package| dcv_packages_path + package }
    install_package_list(dcv_packages)

    # Create Python virtual env for the external authenticator
    install_ext_auth_virtual_env

    post_install
  end

  # Switch runlevel to multi-user.target for official ami
  if node['cluster']['is_official_ami_build']
    execute "set default systemd runlevel to multi-user.target" do
      command "systemctl set-default multi-user.target"
    end
  end
end
