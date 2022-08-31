# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: neuron
#
# Copyright:: 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

return if node['cluster']['base_os'] == 'centos7' || arm_instance?

# Skip installation if Trainium or Inferentia drivers are already installed.
# Inferentia packages might be installed in old DLAMIs and they will conflict with Neuron packages
return if is_package_installed?("aws-neuronx-dkms") || is_package_installed?("aws-neuron-dkms")

# add neuron repository
if platform?('amazon')
  yum_repository "neuron" do
    description "Neuron YUM Repository"
    baseurl node['cluster']['neuron']['base_url']
    gpgkey node['cluster']['neuron']['public_key']
    retries 3
    retry_delay 5
  end

elsif platform?('ubuntu')
  apt_repository 'neuron' do
    uri node['cluster']['neuron']['base_url']
    components ['main']
    key node['cluster']['neuron']['public_key']
    retries 3
    retry_delay 5
  end

  apt_update
end

package node['cluster']['neuron']['packages'] do
  retries 10
  retry_delay 5
end

kernel_module 'neuron'
