# frozen_string_literal: true

# Copyright:: 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

provides :cloudwatch, platform: 'amazon' do |node|
  node['platform_version'].to_i == 2023
end

use 'partial/_cloudwatch_common'
use 'partial/_cloudwatch_install_package_rhel'

action :cloudwatch_prerequisite do
  package "gnupg2-full" do
    options '--allowerasing'
    retries 3
    retry_delay 5
  end
  # on alinux2023, install and enable ryslog: https://repost.aws/knowledge-center/ec2-linux-al2023-find-log-files
  package "rsyslog" do
    retries 3
    retry_delay 5
  end
  service 'rsyslog' do
    supports restart: true
    action %i(enable start)
    retries 5
    retry_delay 10
  end unless on_docker?
end

action_class do
  def platform_url_component
    'amazon_linux'
  end
end
