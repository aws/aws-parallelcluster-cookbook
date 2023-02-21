# frozen_string_literal: true

#
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
# Default resource implementation
provides :lustre, platform: 'centos' do |node|
  node['platform_version'].to_i == 7
end

use 'partial/_install_lustre_centos_redhat'
use 'partial/_install_lustre_old_centos'

default_action :setup

action :setup do
  if %w(7.5 7.6).include?(node['platform_version'].to_f)
    action_install_lustre_old_centos
  elsif node['platform_version'].to_f >= 7.7
    action_install_lustre
  elsif Chef::Log.warn("Unsupported version of Centos, #{node['platform_version']}, supported versions are >= 7.5")
    # Centos 6
  end
end
