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

provides :system_authentication, platform: 'amazon' do |node|
  node['platform_version'].to_i == 2023
end

use 'partial/_system_authentication_common'

action :configure do
  # oddjobd service is required for creating homedir
  service "oddjobd" do
    action %i(start enable)
  end unless on_docker?

  execute 'Configure Directory Service' do
    user 'root'
    # Tell NSS, PAM to use SSSD for system authentication and identity information
    # authconfig is a compatibility tool, replaced by authselect
    command "authselect select sssd with-mkhomedir"
    sensitive true
    default_env true
  end
end

action_class do
  def required_packages
    %w(sssd sssd-tools sssd-ldap authselect oddjob-mkhomedir)
  end
end
