# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: chrony
#
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

service node['cluster']['chrony']['service'] do
  # chrony service supports restart but is not correctly checking if the process is stopped before starting the new one
  supports restart: false
  reload_command chrony_reload_command
  action %i(enable start)
end unless virtualized?
