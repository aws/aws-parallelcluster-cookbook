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
# ADC (us-iso*) can't reach CloudFront and its EFS S3 buckets only host the
# efs-utils source tarball (not a served repo), so there we build the RPM locally.

def efs_repo_base_url
  # RHEL/Rocky are el-binary-compatible, so both use the redhat/<major>.* path.
  "#{efs_domain}/repo/rpm/redhat/#{node['platform_version'].to_i}.*"
end

def efs_adc_tarball
  "efs-utils-v#{_efs_utils_version.tr('.', '-')}-1.tar.gz"
end

def efs_adc_tarball_url
  "https://s3.#{aws_region}.#{aws_domain}/s3-efs-utils-mvp-prod-#{aws_region}/linux/#{efs_adc_tarball}"
end

def efs_build_prerequisites
  # This set is provided by EFS team.
  %w(git rpm-build make rust cargo openssl-devel gcc gcc-c++ cmake wget perl golang)
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
  # Import the repo's GPG key into the rpm keyring up front, before the repo is
  # read. With repo_gpgcheck=true the metadata signature is verified on every
  # `yum repolist`/makecache, and if the key isn't already trusted, dnf on RHEL9
  # prompts interactively ("Is this ok [y/N]") and hangs non-interactive runs.
  # Mirrors the official efs-utils installer (rpm --import + local file:// gpgkey).
  efs_utils_gpg_key = "#{node['cluster']['sources_dir']}/efs-utils-armored.gpg"

  remote_file efs_utils_gpg_key do
    source "#{efs_domain}/efs-utils-armored.gpg"
    mode '0644'
    retries 3
    retry_delay 5
  end

  execute "import efs-utils gpg key" do
    command "rpm --import #{efs_utils_gpg_key}"
  end

  yum_repository "efs-utils" do
    description "efs-utils repository"
    baseurl efs_repo_base_url
    gpgkey "file://#{efs_utils_gpg_key}"
    gpgcheck true
    repo_gpgcheck true
    enabled true
    retries 3
    retry_delay 5
  end

  action_install_efs_utils_within_major
end

action :install_efs_utils_from_s3 do
  robust_package 'install efs-utils build prerequisites' do
    packages efs_build_prerequisites
  end

  local_tarball = "#{node['cluster']['sources_dir']}/#{efs_adc_tarball}"
  remote_file local_tarball do
    source efs_adc_tarball_url
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  # The tarball extracts to efs-utils/; `make rpm` writes the RPMs to build/.
  bash "install amazon-efs-utils from S3 tarball" do
    user 'root'
    cwd node['cluster']['sources_dir']
    code <<-EFSUTILSINSTALL
      set -e
      rm -rf efs-utils
      tar xf #{local_tarball}
      cd efs-utils
      make rpm
      yum install -y ./build/amazon-efs-utils*rpm
    EFSUTILSINSTALL
    retries 3
    retry_delay 5
  end
end
