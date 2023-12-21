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
      '37aaaabfe1b8dde83254c738aa562b7eb7b1663cea09a53cedf9dabe5ddbb184'
    when "el8"
      'c5366bde8fb49bb41f2bb04e3390e5bda9aa668c0122e4fbf663e9a18c049edf'
    when "el9"
      '07148327f30dae656b338e24102945830601e85df4e135029b624df1e9ee3c2e'
    else
      ''
    end
  else
    case el_string
    when "el7"
      'e82e434a3f0c5d1a48d7cda2b6100ce51ae250d93b6a17b2fb81ba0fda463b3b'
    when "el8"
      '28a15bb557f59580f3b58d9bf99430d27d98efbaa9007ab3b2eca46e1a51fa4f'
    when "el9"
      'eb906f41b0a064005499ab6a1be42c8d218a3fbaf9444cb907990aa6171bdea4'
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
