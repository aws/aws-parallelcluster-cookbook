# frozen_string_literal: true
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

action :install_package do
  # For ubuntu, CINC17 apt-package resources need full versions for `version`
  execute "install_fabricmanager_for_ubuntu" do
    command "apt -y install #{node['cluster']['nvidia']['fabricmanager']['package']}=#{node['cluster']['nvidia']['fabricmanager']['version']} "\
            "&& apt-mark hold #{node['cluster']['nvidia']['fabricmanager']['package']}"
    retries 3
    retry_delay 5
  end
end
