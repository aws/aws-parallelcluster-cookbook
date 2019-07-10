#
# Cookbook Name:: aws-parallelcluster
# Recipe:: dcv_install
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

def install_rpm_packages_from_path(packages)
  packages.each do |pack|
    package pack do
      action :install
      source pack
    end
  end
end

def install_ext_auth_virtual_env
  unless File.exist?("#{node['cfncluster']['dcv_ext_auth_virtualenv_path']}/bin/activate")
    pyenv_install node['cfncluster']['dcv']['ext_auth_user'] do
      python_version node['cfncluster']['python-version']
    end

    activate_virtual_env node['cfncluster']['dcv_ext_auth_virtualenv'] do
      pyenv_path node['cfncluster']['dcv_ext_auth_virtualenv_path']
      pyenv_user node['cfncluster']['dcv']['ext_auth_user']
      python_version node['cfncluster']['python-version']
      requirements_path "ext_auth_files/requirements.txt"
    end
  end
end


if node['platform'] == 'centos' and node['platform_version'].to_i == 7
  case node['cfncluster']['cfn_node_type']
  when 'MasterServer', nil
      dcv_tarball = "#{node['cfncluster']['sources_dir']}/dcv-#{node['cfncluster']['dcv']['version']}.tgz"

      execute 'gnomeDesktop' do
        command 'yum -y install @gnome'
      end

      unless File.exist?(dcv_tarball)
        remote_file dcv_tarball do
          source node['cfncluster']['dcv']['url']
          mode '0644'
          retries 3
          retry_delay 5
        end

        bash 'extract dcv packages' do
          cwd Chef::Config[:file_cache_path]
          code "tar -xvzf #{dcv_tarball}"
        end
      end

      dcv_packages = %W(#{node['cfncluster']['dcv']['server']} #{node['cfncluster']['dcv']['xdcv']})
      path = "#{Chef::Config[:file_cache_path]}/nice-dcv-#{node['cfncluster']['dcv']['version']}-el7/"
      dcv_packages.map! {|x|  path + x}
      install_rpm_packages_from_path(dcv_packages)

      user node['cfncluster']['dcv']['ext_auth_user'] do
        manage_home true
        home node['cfncluster']['dcv']['ext_auth_user_home']
        comment 'Required for DCV'
        system true
        shell '/bin/bash'
      end

      install_ext_auth_virtual_env

  when 'ComputeFleet'
      user node['cfncluster']['dcv']['ext_auth_user'] do
        manage_home false
        home node['cfncluster']['dcv']['ext_auth_user_home']
        comment 'ext auth user'
        system true
        shell '/bin/bash'
      end
  end

  service "firewalld" do
    action [ :disable, :stop ]
  end
end
