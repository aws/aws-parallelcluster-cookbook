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

def dcv_sha256sum
  if arm_instance?
    case el_string
    when "el7"
      # ALINUX2 and Centos7
      'e5a8549b35b2c45d960a2b22a521542cb97458c2c7c7d0c2bf0c4045f4f7f974'
    when "el8"
      # RHEL and Rocky8
      'f0c8ebf9d240846004b5e321d48d90f7d9d2d36a769b9dacf59ea37d51cc5ceb'
    when "el9"
      # RHEL and Rocky9
      'b13e92991427bea4ecdbcf472a64c875abfc08f15e63bc3d935d603ac971975a'
    else
      ''
    end
  else
    case el_string
    when "el7"
      # ALINUX2 and Centos7
      '400691a92f23c59492896ad4906c5a4a827cdbce53fa6291f5bad43fd47ebd1a'
    when "el8"
      # RHEL and Rocky8
      'a0d17663c2f8597e329ccbc2edf30fbb04ef4ba7dfefe9cb57badde8b964da7c'
    when "el9"
      # RHEL and Rocky9
      'b8cb9a398bb2da666426f607627fa2da5173dc4ca93f6180f872cc05ad6fff7a'
    else
      ''
    end
  end
end

def el_string
  if platform?('amazon')
    "el7"
  else
    "el#{node['platform_version'].to_i}"
  end
end

def dcv_package
  "nice-dcv-#{node['cluster']['dcv']['version']}-#{el_string}-#{dcv_url_arch}"
end

def dcv_server
  "nice-dcv-server-#{node['cluster']['dcv']['server']['version']}.#{el_string}.#{dcv_url_arch}.rpm"
end

def xdcv
  "nice-xdcv-#{node['cluster']['dcv']['xdcv']['version']}.#{el_string}.#{dcv_url_arch}.rpm"
end

def dcv_web_viewer
  "nice-dcv-web-viewer-#{node['cluster']['dcv']['web_viewer']['version']}.#{el_string}.#{dcv_url_arch}.rpm"
end

def dcv_gl
  "nice-dcv-gl-#{node['cluster']['dcv']['gl']['version']}.#{el_string}.#{dcv_url_arch}.rpm"
end

action_class do
  def pre_install
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
      action %i(disable stop)
    end
  end

  def post_install
    # stop firewall
    service "firewalld" do
      action %i(disable stop)
    end

    include_recipe 'aws-parallelcluster-platform::disable_selinux'
  end

  def install_dcv_gl
    package = "#{node['cluster']['sources_dir']}/#{dcv_package}/#{dcv_gl}"
    package package do
      action :install
      source package
    end
  end
end
