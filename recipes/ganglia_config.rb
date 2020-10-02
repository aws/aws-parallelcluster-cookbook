# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: ganglia_config
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

if node['cfncluster']['ganglia_enabled'] == 'yes' || node['cfncluster']['ganglia_enabled'] == true
  case node['cfncluster']['cfn_node_type']
  when 'MasterServer'
    case node['platform']
    when "redhat", "centos", "amazon", "scientific" # ~FC024
      cookbook_file 'ganglia-webfrontend.conf' do
        path '/etc/httpd/conf.d/ganglia.conf'
        user 'root'
        group 'root'
        mode '0644'
      end
    when "ubuntu"
      directory '/var/lib/ganglia/rrds' do
        owner 'ganglia'
        group 'ganglia'
        mode 0755
        recursive true
        action :create
      end

      # Setup ganglia-web.conf apache config
      execute "copy ganglia apache conf" do
        command "cp /etc/ganglia-webfrontend/apache.conf /etc/apache2/sites-enabled/ganglia.conf"
        not_if "test -f /etc/apache2/sites-enabled/ganglia.conf"
      end
    end

    template '/etc/ganglia/gmetad.conf' do
      source 'gmetad.conf.erb'
      owner 'root'
      group 'root'
      mode '0644'
    end

    service "gmetad" do
      supports restart: true
      action %i[enable restart]
    end

    service node['cfncluster']['ganglia']['httpd_service'] do
      supports restart: true, reload: true
      action %i[enable restart]
    end
  end

  # For ComputeFleet and MasterServer

  if node['platform'] == 'centos' && node['platform_version'].to_i >= 7 || node['platform'] == 'amazon' && node['platform_version'].to_i == 2
    # Fix circular dependency multi-user.target -> cloud-init-> gmond -> multi-user.target
    # gmond is started by chef during cloud-init, but gmond service is configured to start after multi-user.target
    # which doesn't start until cloud-init run is finished. So gmond service is stuck into starting, which keep
    # hanging chef until the 600s timeout.
    replace_or_add "change gmond service dependency" do
      path "/usr/lib/systemd/system/gmond.service"
      pattern "After=multi-user.target"
      line "After=network.target"
      replace_only true
    end
  end

  template '/etc/ganglia/gmond.conf' do
    source 'gmond.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end

  service node['cfncluster']['ganglia']['gmond_service'] do
    supports restart: true
    action %i[enable restart]
  end
end
