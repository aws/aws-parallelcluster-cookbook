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

# This works for RedHat 8 and Centos >= 7.7
action :install_lustre do
  # add fsx lustre repository
  yum_repository "aws-fsx" do
    description "AWS FSx Packages - $basearch"
    baseurl node['cluster']['lustre']['base_url']
    gpgkey node['cluster']['lustre']['public_key']
    retries 3
    retry_delay 5
  end

  package %w(kmod-lustre-client lustre-client) do
    retries 3
    retry_delay 5
  end

  kernel_module 'lnet' unless virtualized?
end
