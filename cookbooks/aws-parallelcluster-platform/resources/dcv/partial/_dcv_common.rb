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
    return if ::File.exist?("#{dcvauth_virtualenv_path}/bin/activate")

    install_pyenv 'pyenv for default python version'

    activate_virtual_env dcvauth_virtualenv do
      pyenv_path dcvauth_virtualenv_path
      python_version node['cluster']['python-version']
    end
  end

  # Function to disable lock screen since default EC2 users don't have a password
  def disable_lock_screen
    # Override default GSettings to disable lock screen for all the users
    cookbook_file "/usr/share/glib-2.0/schemas/10_org.gnome.desktop.screensaver.gschema.override" do
      source 'dcv/10_org.gnome.desktop.screensaver.gschema.override'
      cookbook 'aws-parallelcluster-platform'
      owner 'root'
      group 'root'
      mode '0755'
    end

    # compile gsettings schemas
    execute 'Compile gsettings schema' do
      command "glib-compile-schemas /usr/share/glib-2.0/schemas/"
    end
  end

  def post_install
    # empty by default
  end

  # Configure the system to enable NICE DCV to have direct access to the Linux server's GPU and enable GPU sharing.
  def allow_gpu_acceleration
    # Update the xorg.conf to set up NVIDIA drivers.
    # NOTE: --enable-all-gpus parameter is needed to support servers with more than one NVIDIA GPU.
    nvidia_xconfig_command = "nvidia-xconfig --preserve-busid --enable-all-gpus"
    nvidia_xconfig_command += " --use-display-device=none" if node['ec2']['instance_type'].start_with?("g2.")
    execute "Set up Nvidia drivers for X configuration" do
      user 'root'
      command nvidia_xconfig_command
    end

    # dcvgl package must be installed after NVIDIA and before starting up X
    # DO NOT install dcv-gl on non-GPU instances, or will run into a black screen issue
    install_dcv_gl

    # Configure the X server to start automatically when the Linux server boots and start the X server in background
    bash 'Launch X' do
      user 'root'
      code <<-SETUPX
      set -e
      systemctl set-default graphical.target
      systemctl isolate graphical.target &
      SETUPX
    end

    # Verify that the X server is running
    execute 'Wait for X to start' do
      user 'root'
      command "pidof X || pidof Xorg"
      retries 5
      retry_delay 5
    end
  end

  def optionally_disable_rnd
    # do nothing
  end
end

action :setup do
  return if ::File.exist?("/etc/dcv/dcv.conf")
  return if redhat_ubi?

  # share values with InSpec tests and configuration recipes
  node.default['conditions']['dcv_supported'] = dcv_supported?
  node.default['cluster']['dcv']['authenticator']['virtualenv_path'] = dcvauth_virtualenv_path
  node_attributes 'dump node attributes'

  directory node['cluster']['scripts_dir'] do
    recursive true
  end

  directory node['cluster']['sources_dir'] do
    recursive true
  end

  # Install pcluster_dcv_connect.sh script in all the OSes to use it for error handling
  cookbook_file "#{node['cluster']['scripts_dir']}/pcluster_dcv_connect.sh" do
    source 'dcv/pcluster_dcv_connect.sh'
    cookbook 'aws-parallelcluster-platform'
    owner 'root'
    group 'root'
    mode '0755'
    action :create_if_missing
  end

  if dcv_supported?
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

    pre_install

    disable_lock_screen

    # Extract DCV packages
    unless ::File.exist?(dcv_tarball)
      remote_file dcv_tarball do
        source dcv_url
        checksum dcv_sha256sum
        mode '0644'
        retries 3
        retry_delay 5
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

action :configure do
  # share values with InSpec tests and configuration recipes
  node.default['conditions']['dcv_supported'] = dcv_supported?
  node.default['cluster']['dcv']['authenticator']['virtualenv_path'] = dcvauth_virtualenv_path
  node_attributes 'dump node attributes'

  if dcv_supported? && node['cluster']['node_type'] == "HeadNode"
    if dcv_gpu_accel_supported?
      # Enable graphic acceleration in dcv conf file for graphic instances.
      allow_gpu_acceleration
    else
      bash 'set default systemd runlevel to graphical.target' do
        user 'root'
        code <<-SETUPX
        set -e
        systemctl set-default graphical.target
        systemctl isolate graphical.target &
        SETUPX
      end
    end

    optionally_disable_rnd

    # Install utility file to generate HTTPs certificates for the DCV external authenticator and generate a new one
    cookbook_file "#{node['cluster']['etc_dir']}/generate_certificate.sh" do
      source 'dcv/generate_certificate.sh'
      cookbook 'aws-parallelcluster-platform'
      owner 'root'
      mode '0700'
    end
    execute "certificate generation" do
      # args to the script represent:
      # * path to certificate
      # * path to private key
      # * user to make owner of the two files
      # * group to make owner of the two files
      # NOTE: the last arg is hardcoded to be 'dcv' so that the dcvserver can read the files when authenticating
      command "#{node['cluster']['etc_dir']}/generate_certificate.sh"\
            " \"#{node['cluster']['dcv']['authenticator']['certificate']}\""\
            " \"#{node['cluster']['dcv']['authenticator']['private_key']}\""\
            " #{node['cluster']['dcv']['authenticator']['user']} dcv"
      user 'root'
    end

    # Generate dcv.conf starting from template
    template "/etc/dcv/dcv.conf" do
      action :create
      source 'dcv/dcv.conf.erb'
      cookbook 'aws-parallelcluster-platform'
      owner 'root'
      group 'root'
      mode '0755'
    end

    # Create directory for the external authenticator to store access file created by the users
    directory '/var/spool/parallelcluster/pcluster_dcv_authenticator' do
      owner node['cluster']['dcv']['authenticator']['user']
      mode '1733'
      recursive true
    end

    # Install DCV external authenticator
    cookbook_file "#{node['cluster']['dcv']['authenticator']['user_home']}/pcluster_dcv_authenticator.py" do
      source 'dcv/pcluster_dcv_authenticator.py'
      cookbook 'aws-parallelcluster-platform'
      owner node['cluster']['dcv']['authenticator']['user']
      mode '0700'
    end

    # Start NICE DCV server
    service "dcvserver" do
      action %i(enable start)
    end
  end
end

def dcv_supported?
  true
end

def dcv_pkg_arch
  arm_instance? ? 'arm64' : 'amd64'
end

def dcv_url_arch
  arm_instance? ? 'aarch64' : 'x86_64'
end

def dcv_gpu_accel_supported?
  unsupported_gpu_accel_list = ["g5g."]
  graphic_instance? && nvidia_installed? && !node['ec2']['instance_type'].start_with?(*unsupported_gpu_accel_list)
end

def dcv_url
  "https://d1uj6qtbmh3dt5.cloudfront.net/#{node['cluster']['dcv']['version'].split('-')[0]}/Servers/#{dcv_package}.tgz"
end

def dcv_tarball
  "#{node['cluster']['sources_dir']}/dcv-#{node['cluster']['dcv']['version']}.tgz"
end

def dcvauth_virtualenv
  'dcv_authenticator_virtualenv'
end

def dcvauth_virtualenv_path
  "#{node['cluster']['system_pyenv_root']}/versions/#{node['cluster']['python-version']}/envs/#{dcvauth_virtualenv}"
end
