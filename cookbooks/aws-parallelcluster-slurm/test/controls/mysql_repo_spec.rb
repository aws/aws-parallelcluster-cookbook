# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

control 'tag:install_mysql_repo_added' do
  if os_properties.ubuntu?
    describe file('/etc/apt/sources.list.d/mysql.list') do
      it { should exist }
      its('content') { should match /mysql-apt-config/ }
      its('content') { should match /mysql-8.0/ }
      its('content') { should match /mysql-tools/ }
      its('content') { should match /mysql-tools-preview/ }
    end
  else
    %w(mysql-connectors-community mysql-tools-community mysql80-community).each do |repo_name|
      describe yum.repo(repo_name) do
        it { should exist }
        it { should be_enabled }
      end
    end
  end
end
