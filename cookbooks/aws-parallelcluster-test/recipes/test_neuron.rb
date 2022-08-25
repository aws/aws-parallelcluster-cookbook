# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-test
# Recipe:: test_nvidia
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

ruby_block 'Verify that Neuron repository is enabled' do
  block do
    unless repository_enabled?(node['cluster']['neuron']['repository_name'],
                                  node['cluster']['neuron']['base_url'])
      raise "Missing Neuron repository"
    end
  end
end

if neuron_instance?
  bash "check Neuron module and devices" do
    cwd Chef::Config[:file_cache_path]
    code <<-TEST
      lsmod | grep neuron
      [[ $? == 0 ]] || { echo "ERROR Installed Neuron driver is not working properly: kernel module not loaded"; exit 1; };
      ls -l /dev/neuron*
      [[ $? == 0 ]] || { echo "ERROR Installed Neuron driver is not working properly: device not found"; exit 1; };
    TEST
  end
end
