# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: supervisord
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

# Put supervisord config in place
cookbook_file "supervisord.conf" do
  source "base/supervisord.conf"
  path "/etc/supervisord.conf"
  owner "root"
  group "root"
  mode "0644"
end

# Put supervisord service in place
template "supervisord-service" do
  source "base/supervisord-service.erb"
  path "/etc/systemd/system/supervisord.service"
  owner "root"
  group "root"
  mode "0644"
end
