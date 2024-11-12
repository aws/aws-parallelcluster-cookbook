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
    when "amzn2"
      # ALINUX2
      '894f5a0b2c57bb9433a7124f152b0930d962ab0f2cfc6ea0f1e159893d667e86'
    when "el8"
      # RHEL and Rocky8
      '7647d00782fb7f14668571f1e48fffa2b8b587d878b7632b03f40bbb92a757ad'
    when "el9"
      # RHEL and Rocky9
      'f9b2fa95f84059c7168ef924b7ffe8b6f4d0d69e2e39280096d4bf76fdfb597c'
    else
      ''
    end
  else
    case el_string
    when "amzn2"
      # ALINUX2
      '81e85db767e36c36877879e1d3afc0f20127b9bd81b845fc8599feb9abd04f24'
    when "el8"
      # RHEL and Rocky8
      'f879513272ac351712814bd969e3862fc7717ada9cfdf1ec227876b0e8ebc77d'
    when "el9"
      # RHEL and Rocky9
      '5d631b5c0f2f6b21d0e56023432766994e2de5cc13f22c70a954cd643cde5b84'
    else
      ''
    end
  end
end

def el_string
  if platform?('amazon')
    "amzn2"
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
