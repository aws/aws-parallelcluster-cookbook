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

default['conditions']['lustre_supported'] = platform_supports_lustre_for_architecture?
default['conditions']['intel_mpi_supported'] = !arm_instance?
default['conditions']['intel_hpc_platform_supported'] = !arm_instance? && platform_supports_intel_hpc_platform?
default['conditions']['dcv_supported'] = platform_supports_dcv?
default['conditions']['ami_bootstrapped'] = ami_bootstrapped?
default['conditions']['efa_supported'] = !arm_instance? || (node['cfncluster']['cfn_base_os'] != "centos8")
default['conditions']['overwrite_nfs_template'] = overwrite_nfs_template?
default['conditions']['arm_pl_supported'] = arm_instance?
