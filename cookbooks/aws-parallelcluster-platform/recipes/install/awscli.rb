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
region = aws_region
awscli_url = "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip"

if region.start_with?("us-iso-")
  awscli_url = "https://aws-sdk-common-infra-dca-prod-deployment-bucket.s3.#{aws_region}.#{aws_domain}/aws-cli-v2/linux/x86_64/awscli-exe-linux-x86_64.zip"
elsif region.start_with?("us-isob-")
  awscli_url = "https://aws-sdk-common-infra-lck-prod-deployment-bucket.s3.#{aws_region}.#{aws_domain}/aws-cli-v2/linux/x86_64/awscli-exe-linux-x86_64.zip"
end

remote_file 'download awscli bundle from s3' do
  path "#{file_cache_path}/awscli-bundle.zip"
  source awscli_url
  path
  retries 5
  retry_delay 5
end

archive_file 'extract awscli bundle' do
  path "#{file_cache_path}/awscli-bundle.zip"
  destination "#{file_cache_path}/awscli"
  overwrite true
end

if region.start_with?("us-iso")
  bash 'install awscli' do
    code "#{file_cache_path}/awscli/aws/install -i /usr/local/aws -b /usr/local/bin"
  end

  cookbook_file "#{node['cluster']['scripts_dir']}/iso-ca-bundle-config.sh" do
    source 'isolated/iso-ca-bundle-config.sh'
    cookbook 'aws-parallelcluster-platform'
    owner 'root'
    group 'root'
    mode '0755'
    action :create_if_missing
  end

  execute "patch ca bundle" do
    command "sh #{node['cluster']['scripts_dir']}/iso-ca-bundle-config.sh"
  end
else
  bash 'install awscli' do
    code "#{cookbook_virtualenv_path}/bin/python #{file_cache_path}/awscli/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws"
  end
end
