# frozen_string_literal: true

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

property :repo_name, String, required: %i(add remove)
property :baseurl, String, required: %i(add)
property :gpgkey, String, required: %i(add)
property :distribution, String, default: "/"
property :disable_modularity, [true, false], default: false

action :add do
  repo_name = new_resource.repo_name.dup
  baseurl = new_resource.baseurl.dup
  gpgkey = new_resource.gpgkey.dup
  disable_modularity = new_resource.disable_modularity.dup
  yum_repository repo_name do
    baseurl baseurl
    gpgkey gpgkey
    retries 3
    retry_delay 5
  end

  bash "Disable modularity" do
    code "echo 'module_hotfixes=1' >> /etc/yum.repos.d/#{repo_name}.repo"
  end if disable_modularity
end

action :remove do
  repo_name = new_resource.repo_name.dup
  yum_repository repo_name do
    action :remove
  end
end
