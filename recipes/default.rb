# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: default
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

include_recipe 'aws-parallelcluster::sge_install'
include_recipe 'aws-parallelcluster::torque_install'
include_recipe 'aws-parallelcluster::slurm_install'

# DCV recipe installs Gnome, X and their dependencies so it must be installed as latest to not break the environment
# used to build the schedulers packages
include_recipe "aws-parallelcluster::dcv_install"
