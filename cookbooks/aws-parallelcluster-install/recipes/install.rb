# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: install
#
# Copyright 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Validate OS type specified by the user is the same as the OS identified by Ohai
validate_os_type

# Update certificates
include_recipe "aws-parallelcluster-install::update_certificates"

# Calling user_ulimit will override every existing limit
user_ulimit "*" do
  filehandle_limit node['cluster']['filehandle_limit']
end

include_recipe 'aws-parallelcluster-install::slurm'
include_recipe 'aws-parallelcluster-install::awsbatch'
include_recipe 'aws-parallelcluster-install::byos'

# DCV recipe installs Gnome, X and their dependencies so it must be installed as latest to not break the environment
# used to build the schedulers packages
include_recipe "aws-parallelcluster-install::dcv"
