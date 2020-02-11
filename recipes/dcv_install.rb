# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: dcv_install
#
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

# Utility function to install a list of packages
def install_package_list(packages)
  packages.each do |package_name|
    case node['platform']
    when 'centos', 'amazon'
      package package_name do
        action :install
        source package_name
      end
    when 'ubuntu'
      execute 'apt install dcv package' do
        command "apt -y install #{package_name}"
      end
    end
  end
end

# Function to install and create a Python virtualenv to run the the External authenticator daemon
def install_ext_auth_virtual_env
  return if File.exist?("#{node['cfncluster']['dcv']['authenticator']['virtualenv_path']}/bin/activate")

  install_pyenv node['cfncluster']['dcv']['authenticator']['user'] do
    python_version node['cfncluster']['python-version']
  end

  create_virtualenv node['cfncluster']['dcv']['authenticator']['virtualenv'] do
    virtualenv_path node['cfncluster']['dcv']['authenticator']['virtualenv_path']
    user node['cfncluster']['dcv']['authenticator']['user']
    python_version node['cfncluster']['python-version']
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

# Install pcluster_dcv_connect.sh script in all the OSes to use it for error handling
cookbook_file "#{node['cfncluster']['scripts_dir']}/pcluster_dcv_connect.sh" do
  source 'dcv/pcluster_dcv_connect.sh'
  owner 'root'
  group 'root'
  mode '0755'
  not_if { ::File.exist?("#{node['cfncluster']['scripts_dir']}/pcluster_dcv_connect.sh") }
end

if node['cfncluster']['dcv']['supported_os'].include?("#{node['platform']}#{node['platform_version'].to_i}") && !File.exist?("/etc/dcv/dcv.conf")
  case node['cfncluster']['cfn_node_type']
  when 'MasterServer', nil
    dcv_tarball = "#{node['cfncluster']['sources_dir']}/dcv-#{node['cfncluster']['dcv']['version']}.tgz"

    # Install DCV pre-requisite packages
    case node['platform']
    when 'centos'
      # Install the desktop environment and the desktop manager packages
      execute 'Install gnome desktop' do
        command 'yum -y install @gnome'
      end
      # Install X Window System (required when using GPU acceleration)
      package "xorg-x11-server-Xorg"

    when 'ubuntu'
      # Install the desktop environment and the desktop manager packages
      # Must purge ifupdown before creating the AMI or the instance will have an ssh failure
      bash 'install pre-req' do
        cwd Chef::Config[:file_cache_path]
        code <<-PREREQ
          set -e
          apt -y install whoopsie
          apt -y install ubuntu-desktop
          apt -y purge ifupdown
          DEBIAN_FRONTEND=noninteractive apt -y install lightdm
          apt -y install mesa-utils
          wget https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY
          gpg --import NICE-GPG-KEY
        PREREQ
      end
    when 'amazon'
      prereq_packages = %W[gdm gnome-session gnome-classic-session gnome-session-xsession
                           xorg-x11-server-Xorg xorg-x11-fonts-Type1 xorg-x11-drivers
                           gnome-terminal gnu-free-fonts-common gnu-free-mono-fonts
                           gnu-free-sans-fonts gnu-free-serif-fonts glx-utils]
      prereq_packages.each do |p|
        package p do
          retries 3
          retry_delay 5
        end
      end
    end
    disable_lock_screen

    # Extract DCV packages
    unless File.exist?(dcv_tarball)
      remote_file dcv_tarball do
        source node['cfncluster']['dcv']['url']
        mode '0644'
        retries 3
        retry_delay 5
      end

      # Verify checksum of dcv package
      ruby_block "verify dcv checksum" do
        block do
          require 'digest'
          checksum = Digest::SHA256.file(dcv_tarball).hexdigest
          if checksum != node['cfncluster']['dcv']['sha256sum']
            raise "Downloaded DCV package checksum #{checksum} does not match expected checksum #{node['cfncluster']['dcv']['package']['sha256sum']}"
          end
        end
      end

      bash 'extract dcv packages' do
        cwd node['cfncluster']['sources_dir']
        code "tar -xvzf #{dcv_tarball}"
      end
    end

    # Install server and xdcv packages
    dcv_packages = %W[#{node['cfncluster']['dcv']['server']} #{node['cfncluster']['dcv']['xdcv']}]
    dcv_packages_path = "#{node['cfncluster']['sources_dir']}/#{node['cfncluster']['dcv']['package']}/"
    # Rewrite dcv_packages object by cycling each package file name and appending the path to them
    dcv_packages.map! { |package| dcv_packages_path + package }
    install_package_list(dcv_packages)

    # Create user and Python virtual env for the external authenticator
    user node['cfncluster']['dcv']['authenticator']['user'] do
      manage_home true
      home node['cfncluster']['dcv']['authenticator']['user_home']
      comment 'NICE DCV External Authenticator user'
      system true
      shell '/bin/bash'
    end
    install_ext_auth_virtual_env

  when 'ComputeFleet'
    user node['cfncluster']['dcv']['authenticator']['user'] do
      manage_home false
      home node['cfncluster']['dcv']['authenticator']['user_home']
      comment 'NICE DCV External Authenticator user'
      system true
      shell '/bin/bash'
    end
  end

  # Post-installation action
  case node['platform']
  when 'centos'
    # stop firewall
    service "firewalld" do
      action %i[disable stop]
    end

    # Disable selinux
    selinux_state "SELinux Disabled" do
      action :disabled
      only_if 'which getenforce'
    end
  end
end
