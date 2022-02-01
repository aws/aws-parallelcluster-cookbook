# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: disable_log4j_patcher
#
# Copyright 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

if platform_family?('amazon')
  # masking the service in order to prevent it from being automatically enabled
  # if not installed yet
  service 'log4j-cve-2021-44228-hotpatch' do
    action %i[disable stop mask]
  end
end
