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

# Install amazon-efs-utils from the EFS yum repo instead of building from source.
# ADC (us-iso*) can't reach CloudFront and its EFS S3 buckets are raw package
# drops (not a served repo), so there we download the RPM and install the file.

def efs_repo_base_url
  # RHEL/Rocky are el-binary-compatible, so both use the redhat/<major>.* path.
  "#{efs_domain}/repo/rpm/redhat/#{node['platform_version'].to_i}.*"
end

def efs_rpm_arch
  arm_instance? ? 'aarch64' : 'x86_64'
end

def efs_rpm_file
  "amazon-efs-utils-#{_efs_utils_version}-1.#{efs_rpm_arch}.rpm"
end

def efs_adc_rpm_url
  # EFS's per-region prebuilt bucket (s3-efs-utils-mvp-prod-<region>), reachable
  # from ADC nodes via the S3 gateway endpoint.
  "https://s3-efs-utils-mvp-prod-#{aws_region}.s3.#{aws_region}.#{aws_domain}/#{efs_rpm_file}"
end

action :install_utils do
  return if _skip_efs_utils_install?

  return if redhat_on_docker?

  return if already_installed?

  if aws_region.start_with?("us-iso")
    action_install_efs_utils_from_s3
  else
    action_install_efs_utils_from_repo
  end

  action_increase_poll_interval
end

action :install_efs_utils_from_repo do
  yum_repository "efs-utils" do
    description "efs-utils repository"
    baseurl efs_repo_base_url
    gpgkey "#{efs_domain}/efs-utils-armored.gpg"
    gpgcheck true
    repo_gpgcheck true
    enabled true
    retries 3
    retry_delay 5
  end

  action_install_efs_utils_within_major
end

action :install_efs_utils_from_s3 do
  local_rpm = "#{node['cluster']['sources_dir']}/#{efs_rpm_file}"
  remote_file local_rpm do
    source efs_adc_rpm_url
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  bash "install amazon-efs-utils from S3 rpm" do
    user 'root'
    cwd node['cluster']['sources_dir']
    code "yum install -y ./#{efs_rpm_file}"
    retries 3
    retry_delay 5
  end
end
