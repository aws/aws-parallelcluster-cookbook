# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

unified_mode true
default_action :setup

action :create_source_link do
  directory node['cluster']['sources_dir'] do
    recursive true
  end

  # Add MySQL source file to be compliant with Licensing
  file "#{node['cluster']['sources_dir']}/mysql_source_code.txt" do
    content %(You can get MySQL source code here:

#{package_source(node['cluster']['artifacts_s3_url'])}
)
    owner 'root'
    group 'root'
    mode '0644'
  end
end

action_class do
  def package_version
    "8.0.36-1"
  end

  def package_source_version
    "8.0.36"
  end

  def package_filename
    "mysql-community-client-#{package_version}.tar.gz"
  end

  def package_root(s3_url)
    "#{s3_url}/mysql"
  end

  def package_archive(s3_url)
    "#{package_root(s3_url)}/#{package_platform}/#{package_filename}"
  end

  def package_source(s3_url)
    "#{s3_url}/source/mysql-#{package_source_version}.tar.gz"
  end
end
