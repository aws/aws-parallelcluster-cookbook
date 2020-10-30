# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: dcv_config
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

# This recipe install the prerequisites required to use NICE DCV on a Linux server
# Source: https://docs.aws.amazon.com/en_us/dcv/latest/adminguide/setting-up-installing-linux-prereq.html

# Configure the system to enable NICE DCV to have direct access to the Linux server's GPU and enable GPU sharing.
def allow_gpu_acceleration
  # On CentOS fix circular dependency multi-user.target -> cloud-init-> isolate multi-user.target.
  # multi-user.target doesn't start until cloud-init run is finished. So isolate multi-user.target
  # is stuck into starting, which keep hanging chef until the 3600s timeout.
  unless node['platform'] == 'centos'
    # Turn off X
    execute "Turn off X" do
      command "systemctl isolate multi-user.target"
    end
  end

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
  dcv_gl = "#{node['cfncluster']['sources_dir']}/#{node['cfncluster']['dcv']['package']}/#{node['cfncluster']['dcv']['gl']}"
  case node['platform']
  when 'centos', 'amazon'
    package dcv_gl do
      action :install
      source dcv_gl
    end
  when 'ubuntu'
    execute 'apt install dcv-gl' do
      command "apt -y install #{dcv_gl}"
    end
  end

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

if node['conditions']['dcv_supported'] && node['cfncluster']['cfn_node_type'] == "MasterServer"
  # be sure to have DCV packages installed
  include_recipe "aws-parallelcluster::dcv_install"

  node.default['cfncluster']['dcv']['is_graphic_instance'] = graphic_instance?

  if node.default['cfncluster']['dcv']['is_graphic_instance']
    # Enable graphic acceleration in dcv conf file for graphic instances.
    allow_gpu_acceleration
  end

  case node['platform']
  when 'ubuntu'
    # Disable RNDFILE from openssl to avoid error during certificate generation
    # See https://github.com/openssl/openssl/issues/7754#issuecomment-444063355
    execute 'No RND' do
      user 'root'
      command "sed --in-place '/RANDFILE/d' /etc/ssl/openssl.cnf"
    end
  when 'centos'
    if node['platform_version'].to_i >= 8
      # Wayland, the default GNOME Display Manager for CentOS 8, is not supported by DCV
      Chef::Log.info("Disabling Wayland and force login screen to use Xorg")
      replace_or_add "Disable Wayland in /etc/gdm/custom.conf" do
        path "/etc/gdm/custom.conf"
        pattern ".*WaylandEnable.*"
        line "WaylandEnable=false"
        replace_only true
      end
    end
  end

  # Install utility file to generate HTTPs certificates for the DCV external authenticator and generate a new one
  cookbook_file "/etc/parallelcluster/generate_certificate.sh" do
    source 'dcv/generate_certificate.sh'
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
    command "/etc/parallelcluster/generate_certificate.sh \"#{node['cfncluster']['dcv']['authenticator']['certificate']}\" \"#{node['cfncluster']['dcv']['authenticator']['private_key']}\" #{node['cfncluster']['dcv']['authenticator']['user']} dcv"
    user 'root'
  end

  # Generate dcv.conf starting from template
  template "/etc/dcv/dcv.conf" do
    action :create
    source 'dcv.conf.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end

  # Create directory for the external authenticator to store access file created by the users
  directory '/var/spool/parallelcluster/pcluster_dcv_authenticator' do
    owner node['cfncluster']['dcv']['authenticator']['user']
    mode '1733'
    recursive true
  end

  # Install DCV external authenticator
  cookbook_file "#{node['cfncluster']['dcv']['authenticator']['user_home']}/pcluster_dcv_authenticator.py" do
    source 'dcv/pcluster_dcv_authenticator.py'
    owner node['cfncluster']['dcv']['authenticator']['user']
    mode '0700'
  end

  # Start NICE DCV server
  service "dcvserver" do
    action %i[enable start]
  end
end
