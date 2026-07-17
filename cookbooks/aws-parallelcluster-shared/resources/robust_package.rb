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

#
# Resource:: robust_package
#
# Cross-platform wrapper around the Chef `package` resource that uses a
# metadata-refresh + mirror-rotation retry strategy on RHEL/Rocky to mitigate
# transient build-image failures caused by out-of-sync RHUI mirrors.
#
# On Amazon Linux and Debian-based platforms the resource falls back to the
# stock Chef `package` resource (with retries) so behavior is unchanged there.
#
# @example
#   robust_package 'install enroot prerequisites' do
#     packages prerequisites
#   end
#

provides :robust_package
unified_mode true

property :packages, [String, Array], required: true, name_property: false
property :max_retries, Integer, default: 10
property :retry_delay, Integer, default: 5

default_action :install

action :install do
  packages = Array(new_resource.packages)
  max_retries = new_resource.max_retries
  retry_delay = new_resource.retry_delay

  if platform?('redhat', 'rocky')
    ruby_block "robust_package install #{new_resource.name}" do
      block do
        dnf_install_with_refresh(packages, max_retries: max_retries, retry_delay: retry_delay)
      end
    end
  else
    package packages do
      retries max_retries
      retry_delay retry_delay
    end
  end
end
