# frozen_string_literal: true

# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe "aws-parallelcluster-environment::isolated_install"
include_recipe "aws-parallelcluster-environment::cfn_bootstrap"
nfs 'install NFS daemon'
ephemeral_drives 'install'
ec2_udev_rules 'configure udev'
cloudwatch 'Install amazon-cloudwatch-agent'
efa 'Install EFA'
lustre "Install FSx options" # FSx options
efs 'Install efs-utils'
stunnel 'Install stunnel'
system_authentication "Install packages required for directory service integration"
