# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-platform
# Recipe:: disable_kernel_modules
#
# Copyright:: 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Disable kernel modules defined in node['cluster']['disable_kernel_modules'].
# The :disable action creates a fake install entry in /etc/modprobe.d that prevents
# the module from being loaded.

node['cluster']['disable_kernel_modules'].each do |mod_name|
  kernel_module mod_name do
    action :disable
  end
end
