# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _nvidia_config
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
# (not available on alinux)
unless node['cfncluster']['cfn_base_os'] == 'alinux'
  if get_nvswitches > 1
    service 'nvidia-fabricmanager' do
      action [:start, :enable]
      supports status: true
    end
  end
end
