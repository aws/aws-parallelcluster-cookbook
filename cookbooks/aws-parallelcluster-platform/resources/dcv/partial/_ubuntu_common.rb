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

def dcv_package
  "nice-dcv-#{node['cluster']['dcv']['version']}-#{node['cluster']['base_os']}-#{dcv_url_arch}"
end

def dcv_server
  "nice-dcv-server_#{node['cluster']['dcv']['server']['version']}_#{dcv_pkg_arch}.#{node['cluster']['base_os']}.deb"
end

def xdcv
  "nice-xdcv_#{node['cluster']['dcv']['xdcv']['version']}_#{dcv_pkg_arch}.#{node['cluster']['base_os']}.deb"
end

def dcv_web_viewer
  "nice-dcv-web-viewer_#{node['cluster']['dcv']['web_viewer']['version']}_#{dcv_pkg_arch}.#{node['cluster']['base_os']}.deb"
end

def dcv_gl
  "/nice-dcv-gl_#{node['cluster']['dcv']['gl']['version']}_#{dcv_pkg_arch}.#{node['cluster']['base_os']}.deb"
end

action_class do
  def pre_install
    apt_update

    # ubuntu-desktop comes with NetworkManager. On a cloud instance NetworkManager is unnecessary and causes delay.
    # Instruct Netplan to use networkd for better performance,
    # and avoid network disruption when installing ubuntu-desktop.
    bash 'Instruct Netplan to use networkd' do
      code <<-NETPLAN
        set -e
        cat > /etc/netplan/95-parallelcluster-force-networkd.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
EOF
        netplan apply
      NETPLAN
    end unless on_docker?

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
      execute "apt install dcv package #{package_name}" do
        command "apt -y install #{package_name}"
        retries 3
        retry_delay 5
      end
    end
  end

  def install_dcv_gl
    execute 'apt install dcv-gl' do
      command "apt -y install #{node['cluster']['sources_dir']}/#{dcv_package}/#{dcv_gl}"
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

  # Disable Wayland in GDM to ensure Xorg is used
  # This is required for Ubuntu 22.04+ where Wayland is the default
  # Without this, GDM won't start Xorg on headless GPU instances
  def disable_wayland
    bash 'Disable Wayland in GDM' do
      user 'root'
      code <<-DISABLEWAYLAND
        set -e
        if [ -f /etc/gdm3/custom.conf ]; then
          sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
          # If the line doesn't exist at all, add it under [daemon] section
          if ! grep -q "^WaylandEnable=false" /etc/gdm3/custom.conf; then
            sed -i '/\\[daemon\\]/a WaylandEnable=false' /etc/gdm3/custom.conf
          fi
        fi
      DISABLEWAYLAND
    end
  end

  # Override allow_gpu_acceleration to disable Wayland before starting X
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

    # Disable Wayland to ensure GDM starts Xorg
    disable_wayland

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
      retries 10
      retry_delay 5
    end
  end
end
