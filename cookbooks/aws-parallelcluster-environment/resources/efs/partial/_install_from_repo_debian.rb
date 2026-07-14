# frozen_string_literal: true

#
# Copyright:: 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

# Install amazon-efs-utils from the EFS apt repo instead of building from source.

action :install_utils do
  return if _skip_efs_utils_install?

  return if already_installed?

  # The repo path includes the version (repo/deb/ubuntu/<version>/dists/<version>/...);
  # both the uri and the suite carry it, matching efs-utils-installer.sh.
  apt_repository "efs-utils" do
    uri "#{efs_domain}/repo/deb/ubuntu/#{node['platform_version']}"
    distribution node['platform_version']
    components ['main']
    key "#{efs_domain}/efs-utils.gpg"
    retries 3
    retry_delay 5
  end

  apt_update

  # "=3.*" caps the major (apt picks the newest match). --force-confold/-confdef
  # keep our efs-utils.conf on upgrade; without them dpkg prompts and aborts on EOF.
  execute "install amazon-efs-utils" do
    command "apt-get install -y -o Dpkg::Options::=\"--force-confold\" -o Dpkg::Options::=\"--force-confdef\" 'amazon-efs-utils=#{_efs_utils_major}.*'"
    retries 3
    retry_delay 5
  end

  action_increase_poll_interval
end
