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
      '4b77afb807c4aa87e0ac958223f12887d4fc2f1e95adf313cf42025b94adfed8'
    when "amzn2023"
      # ALINUX2023
      "60001ea60e91513b5c5018c38c2178cb0fac5cd0f15875ccf694ab95d7cfe661"
    when "el8"
      # RHEL and Rocky8
      '1f59654f27e5f6c148bdc8520994fe2a150a84650af3bc9fefce7f07ff7d310d'
    when "el9"
      # RHEL and Rocky9
      '59ed3e6b2698aad03112d759f8bf9a6ffa6850fdf1072fa4afb4756e7314e19d'
    else
      ''
    end
  else
    case el_string
    when "amzn2"
      # ALINUX2
      '3b9a0ad9c9d521b8a9f6d5c2db0640bd97413d34fe32d418a8a7fd9cae7cc828'
    when "amzn2023"
      # ALINUX2023
      "35128b988dee4f1f4582bd912dc4764b8712c1f0e3a35082a5da7e039eb7ff92"
    when "el8"
      # RHEL and Rocky8
      'b9d24624b857d4315bcd5d90047d18d4924940153d98828b67ae78521916dd83'
    when "el9"
      # RHEL and Rocky9
      '473b439f95a3354c99718d97338256a280431c7103b5d4bed0d8d63dfc8f6312'
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
      download_cmd = if el_string == 'amzn2'
                       "yum install --downloadonly --downloaddir=#{dcv_gl_deps_dir} #{dcv_gl_package}"
                     else
                       "dnf download --destdir=#{dcv_gl_deps_dir} --resolve #{dcv_gl_package}"
                     end
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
    end

    package = "#{node['cluster']['sources_dir']}/#{dcv_package}/#{dcv_gl}"
    # Install dcv-gl without repo access
    execute 'install dcv-gl offline' do
      command "rpm -ivh #{package}"
    end
  end
end
