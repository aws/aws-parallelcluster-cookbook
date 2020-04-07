# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: ganglia_install
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

case node['cfncluster']['cfn_node_type']
when 'MasterServer', nil
  case node['platform']
  when "redhat", "centos", "amazon", "scientific" # ~FC024
    package %w[ganglia ganglia-gmond ganglia-gmetad ganglia-web httpd php php-gd rrdtool] do
      retries 3
      retry_delay 5
    end
  when "ubuntu"
    package %w[ganglia-monitor rrdtool gmetad ganglia-webfrontend] do
      retries 3
      retry_delay 5
    end
  end
when 'ComputeFleet'
  case node['platform']
  when "redhat", "centos", "amazon", "scientific" # ~FC024
    package %w[ganglia-gmond] do
      retries 3
      retry_delay 5
    end
  when "ubuntu"
    package %w[ganglia-monitor] do
      retries 3
      retry_delay 5
    end
  end
end
