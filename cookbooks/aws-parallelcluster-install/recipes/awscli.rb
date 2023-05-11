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

package 'unzip'

bash "install awscli" do
  cwd Chef::Config[:file_cache_path]
  code <<-CLI
    set -e
    curl --retry 5 --retry-delay 5 "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    unzip awscli-bundle.zip
    #{cookbook_virtualenv_path}/bin/python awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
  CLI
end unless ::File.exist?("/usr/local/bin/aws") || redhat_ubi?
