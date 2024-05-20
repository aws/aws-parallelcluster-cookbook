# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: external_slurmdbd_disable_unrequired_services
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Most ParallelCluster AMI are configured for Desktop use and so have some active service that is not required
# This recipe will disable some that are certainly unused, like { apache2, cups, ...,  wpa_supplicant }

# The list depends on the base OS
# This was tested on Ubuntu 20.04, Alinux2 and Rocky8
# Others OS should be checked and added

serviceList = %w()
if platform_family?('debian')
  serviceList = %w(apache2 avahi-daemon cups.service ModemManager wpa_supplicant stunnel whoopsie)
elsif platform?('amazon') && node['platform_version'] == "2"
  serviceList = %w(cups.service)
elsif platform?('rocky') && node['platform_version'].to_i == 8
  serviceList = %w(avahi-daemon cups.service ModemManager mlocate-updatedb)
end

# NOTE: we first tried to use the chef `service` resource as follows
#
# service 'example_service' do
#   action [ :stop, :disable ]
#   user 'root'
# end
#
# however it reported "up to date - nothing to do" but the services where still running.
# So we falled back to a direct invocation of systemctl
# we also added `ignore_failure` because if the service is stopped or disabled the return code will be != 0 and
# the command will be considered as failed

serviceList.each do |service_name|
  execute "Stop service #{service_name}" do
    command "systemctl stop #{service_name}"
    user 'root'
    ignore_failure true
  end

  execute "Disable service #{service_name}" do
    command "systemctl disable #{service_name}"
    user 'root'
    ignore_failure true
  end
end
