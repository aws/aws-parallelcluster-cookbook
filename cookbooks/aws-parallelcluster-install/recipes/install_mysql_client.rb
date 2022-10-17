# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: mysql
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

if platform?('ubuntu') && arm_instance?
  package node['cluster']['mysql']['repository']['packages'] do
    retries 3
    retry_delay 5
  end
else

  package_installer = value_for_platform(
    'default' => "yum install -y",
    'ubuntu' => { 'default' => "apt install" }
  )

  mysql_source_key = "#{node['cluster']['mysql']['package']['prefix']}/#{node['cluster']['mysql']['package']['file']}"
  mysql_tar_file = "/tmp/#{node['cluster']['mysql']['package']['file']}"

  # # Remove packages that break MySQL installation
  # package node['cluster']['mysql']['remove']['packages'] do
  #   action :remove
  # end

  bash 'Install MySQL packages' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-MYSQL
      set -e
      #{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3api get-object \
                         --bucket "#{node['cluster']['mysql']['package']['bucket']}" \
                         --key "#{mysql_source_key}" \
                         --region "#{node['cluster']['region']}" \
                         "#{mysql_tar_file}"
      EXTRACT_DIR=$(mktemp -d --tmpdir mysql.XXXXXXX)
      tar xf "#{mysql_tar_file}" --directory "${EXTRACT_DIR}"
      #{package_installer} ${EXTRACT_DIR}/*
    MYSQL
  end

end
