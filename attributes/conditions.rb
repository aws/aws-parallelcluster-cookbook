# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Attributes:: default
#
# Copyright 2013-2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

default['conditions']['lustre_supported'] = (node['platform'] == 'centos' && node['platform_version'].to_i >= 7) \
  || node['platform'] == 'amazon' || node['platform'] == 'ubuntu'
default['conditions']['efa_supported'] = !arm_instance? && platform_supports_efa?
default['conditions']['intel_mpi_supported'] = !arm_instance? && platform_supports_impi?
default['conditions']['intel_hpc_platform_supported'] = !arm_instance? && platform_supports_intel_hpc_platform?
default['conditions']['ami_bootstrapped'] = ami_bootstrapped?
