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

control 'mysql_client_installed' do
  title "MySql client is installed"

  mysql_packages = []
  if os.redhat?
    mysql_packages.concat %w(mysql-community-client-plugins mysql-community-common
       mysql-community-devel mysql-community-libs mysql-community-libs-compat)
  elsif os.debian?
    if os.release == '18.04'
      mysql_packages.concat %w(libmysqlclient-dev libmysqlclient20)
    else
      mysql_packages.concat %w(libmysqlclient-dev libmysqlclient21)
    end
  else
    describe "unsupported OS" do
      pending "support for #{os.name}-#{os.release} needs to be implemented"
    end
  end
  mysql_packages.each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end
end

control 'mysql_client_source_code_configured' do
  title 'MySql client source code is configured in target dir'

  describe file('/opt/parallelcluster/sources/mysql_source_code.txt') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') do
      should eq %(You can get MySQL source code here:

https://us-east-1-aws-parallelcluster.s3.us-east-1.amazonaws.com/archives/source/mysql-8.0.31.tar.gz
)
    end
  end
end
