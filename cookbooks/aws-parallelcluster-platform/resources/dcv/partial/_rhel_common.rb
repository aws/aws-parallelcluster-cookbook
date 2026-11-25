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
    when "amzn2023"
      # ALINUX2023
      "f32d25efc9e15249f2f19622d381d579c15c6fe70cffc437d91b64fc72927065"
    when "el8"
      # RHEL and Rocky8
      '1cba868399eb072b5c4b38dc6280ec81bad7b5cee064a65d45375e336a985138'
    when "el9"
      # RHEL and Rocky9
      '29876a1df890cded7fe25bc9cf71709013c8d7952b8cf918485f92152110bd86'
    else
      ''
    end
  else
    case el_string
    when "amzn2023"
      # ALINUX2023
      "2e698abfd3b207b41dbfbbe3dc9512abac338b8ecf227bb01d53aafcd62ea855"
    when "el8"
      # RHEL and Rocky8
      '2e09c2126d77b9726f02abb4655dce982c6ef29089de4f488e939747645ddf16'
    when "el9"
      # RHEL and Rocky9
      '8429668d63dc86f668c8f53f8b681c381e9948ec0dd067a29d3dd843576cc593'
    else
      ''
    end
  end
end

def el_string
  if platform?('amazon')
    "amzn#{node['platform_version'].to_i}"
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
    if x86_instance?
      # Download dependencies for nice-dcv-gl (for offline installation during cluster creation)
      dcv_gl_deps_dir = "#{node['cluster']['sources_dir']}/dcv-gl-deps"
      dcv_gl_package = "#{node['cluster']['sources_dir']}/#{dcv_package}/#{dcv_gl}"
      directory dcv_gl_deps_dir

      # Use --resolve to download all transitive dependencies
      download_cmd = "dnf download --destdir=#{dcv_gl_deps_dir} --resolve #{dcv_gl_package}"
      execute 'download dcv-gl dependencies' do
        command download_cmd
        retries 3
        retry_delay 5
      end

      # Remove dcv-gl package itself (we only want dependencies in dcv_gl_deps_dir)
      execute 'remove dcv-gl from deps dir' do
        command "rm -f #{dcv_gl_deps_dir}/nice-dcv-gl-*.rpm"
        only_if { ::Dir.exist?(dcv_gl_deps_dir) }
      end
    end

    # stop firewall
    service "firewalld" do
      action %i(disable stop)
    end

    include_recipe 'aws-parallelcluster-platform::disable_selinux'
  end

  def install_dcv_gl
    # The following installation happens during cluster creation time.
    # So `rpm` installation is needed to remove requirement of Internet access.
    # Install dependencies from downloaded RPMs (offline)
    dcv_gl_deps_dir = "#{node['cluster']['sources_dir']}/dcv-gl-deps"
    execute 'install dcv-gl dependencies offline' do
      command "rpm -ivh #{dcv_gl_deps_dir}/*.rpm"
      only_if { ::Dir.exist?(dcv_gl_deps_dir) && !::Dir.empty?(dcv_gl_deps_dir) }
      retries 3
      retry_delay 5
    end

    package = "#{node['cluster']['sources_dir']}/#{dcv_package}/#{dcv_gl}"
    # Install dcv-gl without repo access
    execute 'install dcv-gl offline' do
      command "rpm -ivh #{package}"
      retries 3
      retry_delay 5
    end
  end
end
