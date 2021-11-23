# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: update_certificates
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

package 'ca-certificates' do
  action :upgrade
end

# Prevent Chef from using outdated/distrusted CA certificates
# https://github.com/chef/chef/issues/12126
if node['platform'] == 'ubuntu'
  link '/opt/cinc/embedded/ssl/certs/cacert.pem' do
    to '/etc/ssl/certs/ca-certificates.crt'
  end
else
  link '/opt/cinc/embedded/ssl/certs/cacert.pem' do
    to '/etc/ssl/certs/ca-bundle.crt'
  end
end
