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

    # Disable selinux
    selinux_state "SELinux Disabled" do
      action :disabled
      only_if 'which getenforce'
    end
  end

  def dcv_sha256sum
    if arm_instance?
      "e1828c4c86679726532d29171b0e033a2474185066e0373bccc0f8bfd494f4b7"
    else
      "01a5e7e57f57d306f3e474963e4475078b0ac1df02440c3759e6dfee5cdaeb09"
    end
  end

  def dcv_package
    "nice-dcv-#{node['cluster']['dcv']['version']}-el7-#{node['cluster']['dcv']['url_architecture_id']}"
  end

  def dcv_server
    "nice-dcv-server-#{node['cluster']['dcv']['server']['version']}.el7.#{node['cluster']['dcv']['url_architecture_id']}.rpm"
  end

  def xdcv
    "nice-xdcv-#{node['cluster']['dcv']['xdcv']['version']}.el7.#{node['cluster']['dcv']['url_architecture_id']}.rpm"
  end

  def dcv_web_viewer
    "nice-dcv-web-viewer-#{node['cluster']['dcv']['web_viewer']['version']}.el7.#{node['cluster']['dcv']['url_architecture_id']}.rpm"
  end

  def install_dcv_gl
    dcv_gl = "#{node['cluster']['sources_dir']}/#{dcv_package}/nice-dcv-gl-#{node['cluster']['dcv']['gl']['version']}.el7.#{node['cluster']['dcv']['url_architecture_id']}.rpm"
    package dcv_gl do
      action :install
      source dcv_gl
    end
  end
end
