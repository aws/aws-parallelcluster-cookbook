# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: cuda
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

return unless node['cluster']['nvidia']['enabled'] == 'yes' || node['cluster']['nvidia']['enabled'] == true

# Get CUDA run file
cuda_tmp_runfile = "/tmp/cuda.run"
remote_file cuda_tmp_runfile do
  source node['cluster']['nvidia']['cuda_url']
  mode '0755'
  retries 3
  retry_delay 5
  not_if { ::File.exist?("/usr/local/cuda-#{node['cluster']['nvidia']['cuda_version']}") }
end

# Install CUDA driver
bash 'cuda.run advanced' do
  user 'root'
  group 'root'
  cwd '/tmp'
  code <<-CUDA
    set -e
    ./cuda.run --silent --toolkit --samples
    rm -f /tmp/cuda.run
  CUDA
  creates "/usr/local/cuda-#{node['cluster']['nvidia']['cuda_version']}"
end

# Get CUDA Sample Files
cuda_samples_directory = "/usr/local/cuda-#{node['cluster']['nvidia']['cuda_version']}/samples"
cuda_tmp_sample_file = "/tmp/cuda-sample.tar.gz"
remote_file cuda_tmp_sample_file do
  source node['cluster']['nvidia']['cuda_samples_url']
  mode '0644'
  retries 3
  retry_delay 5
  not_if { ::File.exist?(cuda_samples_directory) }
end

# Unpack CUDA Samples
bash 'cuda.sample install' do
  user 'root'
  group 'root'
  cwd '/tmp'
  code <<-CUDA
    set -e
    tar xf "#{cuda_tmp_sample_file}" --directory "/usr/local/"
    rm -f "#{cuda_tmp_sample_file}"
  CUDA
  creates cuda_samples_directory
end
