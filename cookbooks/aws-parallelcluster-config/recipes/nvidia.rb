# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: nvidia
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Start nvidia fabric manager on NVSwitch enabled systems
if get_nvswitches > 1
  service 'nvidia-fabricmanager' do
    action %i(start enable)
    supports status: true
  end
end

if graphic_instance?
  # NVIDIA GDRCopy
  execute "enable #{node['cluster']['nvidia']['gdrcopy']['service']} service" do
    # Using command in place of service resource because of: https://github.com/chef/chef/issues/12053
    command "systemctl enable #{node['cluster']['nvidia']['gdrcopy']['service']}"
  end
  service node['cluster']['nvidia']['gdrcopy']['service'] do
    action :start
    supports status: true
  end
end
