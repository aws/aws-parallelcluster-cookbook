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

action :setup do
  apt_repository 'fsxlustreclientrepo' do
    uri          "https://fsx-lustre-client-repo.s3.amazonaws.com/ubuntu"
    components   ['main']
    key          "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-ubuntu-public-key.asc"
    retries 3
    retry_delay 5
  end

  apt_update

  package %W(lustre-client-modules-#{node['cluster']['kernel_release']} lustre-client-modules-aws initramfs-tools) do
    retries 3
    retry_delay 5
  end

  kernel_module 'lnet'
end
