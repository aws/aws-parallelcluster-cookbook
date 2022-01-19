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

return if node['conditions']['ami_bootstrapped'] || File.exist?("/etc/dcv/dcv.conf")

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
        retries 3
        retry_delay 5
      end
    end
  end
end

# Function to install and activate a Python virtual env to run the the External authenticator daemon
def install_ext_auth_virtual_env
  return if File.exist?("#{node['cfncluster']['dcv']['authenticator']['virtualenv_path']}/bin/activate")

  install_pyenv node['cfncluster']['python-version'] do
    prefix node['cfncluster']['system_pyenv_root']
  end
  activate_virtual_env node['cfncluster']['dcv']['authenticator']['virtualenv'] do
    pyenv_path node['cfncluster']['dcv']['authenticator']['virtualenv_path']
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

if node['conditions']['dcv_supported']
  case node['cfncluster']['cfn_node_type']
  when 'MasterServer', nil
    dcv_tarball = "#{node['cfncluster']['sources_dir']}/dcv-#{node['cfncluster']['dcv']['version']}.tgz"

    # Install DCV pre-requisite packages
    case node['platform']
    when 'centos'
      # Install the desktop environment and the desktop manager packages
      execute 'Install gnome desktop' do
        command 'yum -y install @gnome'
        retries 3
        retry_delay 5
      end
      # Install X Window System (required when using GPU acceleration)
      package "xorg-x11-server-Xorg" do
        retries 3
        retry_delay 5
      end

      # libvirtd service creates virtual bridge interfaces.
      # It's provided by libvirt-daemon, installed as requirement for gnome-boxes, included in @gnome.
      # Open MPI does not ignore other local-only devices other than loopback:
      # if virtual bridge interface is up, Open MPI assumes that that network is usable for MPI communications.
      # This is incorrect and it led to MPI applications hanging when they tried to send or receive MPI messages
      # see https://www.open-mpi.org/faq/?category=tcp#tcp-selection for details
      service 'libvirtd' do
        action %i[disable stop]
      end

    when 'ubuntu'
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

    when 'amazon'
      prereq_packages = %w[gdm gnome-session gnome-classic-session gnome-session-xsession
                           xorg-x11-server-Xorg xorg-x11-fonts-Type1 xorg-x11-drivers
                           gnu-free-fonts-common gnu-free-mono-fonts gnu-free-sans-fonts
                           gnu-free-serif-fonts glx-utils]
      # gnome-terminal is not yet available AL2 ARM. Install mate-terminal instead
      # NOTE: installing mate-terminal requires enabling the amazon-linux-extras epel topic
      #       which is done in base_install.
      if arm_instance?
        prereq_packages.push('mate-terminal')
      else
        prereq_packages.push('gnome-terminal')
      end
      package prereq_packages do
        retries 10
        retry_delay 5
      end

      # Use Gnome in place of Gnome-classic
      file "Setup Gnome standard" do
        content "PREFERRED=/usr/bin/gnome-session"
        owner "root"
        group "root"
        mode "0755"
        path "/etc/sysconfig/desktop"
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

    # Install server, xdcv, and web viewer packages
    dcv_packages = %W[#{node['cfncluster']['dcv']['server']} #{node['cfncluster']['dcv']['xdcv']} #{node['cfncluster']['dcv']['web_viewer']}]
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

# Switch runlevel to multi-user.target for official ami
if node['cfncluster']['is_official_ami_build'] && node['init_package'] == 'systemd'
  execute "set default systemd runlevel to multi-user.target" do
    command "systemctl set-default multi-user.target"
  end
end
