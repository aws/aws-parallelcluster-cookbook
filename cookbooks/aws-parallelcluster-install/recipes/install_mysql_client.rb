# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: install_mysql_client
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

if platform?('ubuntu')
  package node['cluster']['mysql']['repository']['packages'] do
    retries 3
    retry_delay 5
  end
else

  package_installer = value_for_platform(
    'default' => "yum install -y",
    'ubuntu' => { 'default' => "apt install -y" }
  )

  mysql_archive_url = node['cluster']['mysql']['package']['archive']
  mysql_tar_file = "/tmp/#{node['cluster']['mysql']['package']['file-name']}"

  log "Downloading MySQL packages archive from #{mysql_archive_url}"

  remote_file mysql_tar_file do
    source mysql_archive_url
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(mysql_tar_file) }
  end

  bash 'Install MySQL packages' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-MYSQL
      set -e

      EXTRACT_DIR=$(mktemp -d --tmpdir mysql.XXXXXXX)
      tar xf "#{mysql_tar_file}" --directory "${EXTRACT_DIR}"
      #{package_installer} ${EXTRACT_DIR}/*
    MYSQL
  end

end

# Add MySQL source file
template "#{node['cluster']['sources_dir']}/mysql_source_code.txt" do
  source 'mysql/mysql_source_code.txt.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
