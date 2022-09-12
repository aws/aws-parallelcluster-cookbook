# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: mysql
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

case node['platform']
when "centos", "amazon"

  mysql_local_rpm = "/tmp/#{node['cluster']['mysql']['repository']['definition']}"

  remote_file mysql_local_rpm do
    source node['cluster']['mysql']['repository']['url']
    mode '0644'
    retries 3
    retry_delay 5
  end

  package node['cluster']['mysql']['repository']['name'] do
    source mysql_local_rpm
  end

  package node['cluster']['mysql']['repository']['packages'] do
    retries 3
    retry_delay 5
  end

when "ubuntu"
  unless arm_instance?
    apt_repository node['cluster']['mysql']['repository']['name'] do
      uri node['cluster']['mysql']['repository']['url']
      components ['mysql-8.0']
      key node['cluster']['mysql']['repository']['key']
      retries 3
      retry_delay 5
    end

    apt_update

  end

  package node['cluster']['mysql']['repository']['packages'] do
    retries 3
    retry_delay 5
  end
end
