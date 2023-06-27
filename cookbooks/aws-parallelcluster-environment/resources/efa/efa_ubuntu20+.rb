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
# See the License for the specific language governing permissions and limitations under the License
provides :efa, platform: 'ubuntu' do |node|
  node['platform_version'].to_i >= 20
end

unified_mode true
default_action :setup

use 'partial/_common'
use 'partial/_disable_ptrace_debian'

action :configure do
  node.default['cluster']['efa']['installer_version'] = new_resource.efa_version
  node_attributes 'dump node attributes'

  action_disable_ptrace
end

action_class do
  def conflicting_packages
    %w(libopenmpi-dev)
  end

  def prerequisites
    %w(environment-modules)
  end
end
