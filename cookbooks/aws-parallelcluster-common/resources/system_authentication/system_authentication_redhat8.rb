# frozen_string_literal: true

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

provides :system_authentication, platform: 'redhat' do |node|
  node['platform_version'].to_i == 8
end

unified_mode true
default_action :setup

action :configure do
  execute 'Configure Directory Service' do
    user 'root'
    # Tell NSS, PAM to use SSSD for system authentication and identity information
    # authconfig is a compatibility tool, replaced by authselect
    command "authselect select sssd with-mkhomedir"
    sensitive true
  end unless redhat_ubi?
end

action :setup do
  package %w(sssd sssd-tools sssd-ldap authselect) do
    retries 3
    retry_delay 5
  end unless redhat_ubi?
end
