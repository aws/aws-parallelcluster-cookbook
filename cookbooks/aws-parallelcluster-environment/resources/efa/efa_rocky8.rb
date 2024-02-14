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

provides :efa, platform: 'rocky' do |node|
  node['platform_version'].to_i >= 8
end
unified_mode true
default_action :setup

use 'partial/_common'

action_class do
  def efa_supported?
    if node['platform_version'].to_f < 8.4
      log "EFA is not supported in this Rocky Linux version #{node['platform_version']}, supported versions are >= 8.4" do
        level :warn
      end
      false
    else
      true
    end
  end

  def conflicting_packages
    %w(openmpi-devel openmpi)
  end

  def prerequisites
    %w(environment-modules libibverbs-utils librdmacm-utils rdma-core-devel)
  end
end
