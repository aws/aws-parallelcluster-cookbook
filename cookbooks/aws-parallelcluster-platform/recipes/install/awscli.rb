# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: awscli
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

return if ::File.exist?("/usr/local/bin/aws") || redhat_on_docker?

file_cache_path = Chef::Config[:file_cache_path]

remote_file 'download awscli bundle from s3' do
  path "#{file_cache_path}/awscli-bundle.zip"
  source 'https://s3.amazonaws.com/aws-cli/awscli-bundle.zip'
  path
  retries 5
  retry_delay 5
end

archive_file 'extract awscli bundle' do
  path "#{file_cache_path}/awscli-bundle.zip"
  destination "#{file_cache_path}/awscli"
  overwrite true
end

bash 'install awscli' do
  code "#{cookbook_virtualenv_path}/bin/python #{file_cache_path}/awscli/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws"
end
