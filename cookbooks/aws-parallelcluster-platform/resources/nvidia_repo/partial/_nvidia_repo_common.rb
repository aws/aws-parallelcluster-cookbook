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

unified_mode true
default_action :add

# node.run_state keys recording which local repos this run actually added,
# so :remove only cleans up what :add installed.
DRIVER_REPO_ADDED = 'nvidia_driver_repo_added'
CUDA_REPO_ADDED = 'nvidia_cuda_repo_added'

# Only the driver and CUDA versions are configurable per call; everything else
# (repo URLs and the CUDA driver-version suffix) is read from node attributes.
# The defaults are lazy so the attributes are read at converge time, honoring
# any override applied after the resource class is compiled (e.g. in tests).
property :driver_version, String, default: lazy { node['cluster']['nvidia']['driver_version'] }
property :cuda_version, String, default: lazy { node['cluster']['nvidia']['cuda']['version'] }

action :add do
  return unless nvidia_enabled?
  return if on_docker?

  # Register the NVIDIA driver local repo unless the driver is already installed
  # (e.g. pre-baked AMI). Track it so :remove only cleans up what this run added.
  unless ::File.exist?('/usr/bin/nvidia-smi')
    remote_file driver_repo_package_path do
      source driver_repo_source_url
      mode '0644'
      retries 3
      retry_delay 5
    end
    action_install_driver_repo
    node.run_state[DRIVER_REPO_ADDED] = true
  end

  # Register the CUDA local repo unless CUDA is already installed.
  unless ::File.exist?('/usr/local/cuda')
    remote_file cuda_repo_package_path do
      source cuda_repo_source_url
      mode '0644'
      retries 3
      retry_delay 5
    end
    action_install_cuda_repo
    node.run_state[CUDA_REPO_ADDED] = true
  end

  # Refresh the package manager metadata once, after all local repos have been
  # enrolled, so their package lists (and, on RHEL, the driver repo's DKMS
  # module metadata) are visible to the later nvidia_driver / nvidia_cuda installs.
  action_refresh_repo_cache if node.run_state[DRIVER_REPO_ADDED] || node.run_state[CUDA_REPO_ADDED]
end

action :remove do
  # Only remove each local repo (and its downloaded installer) if this run added it.
  # After removal, refresh the package manager metadata so the removed repo's package
  # list stops advertising NVIDIA packages at the repo's (lower) versions, which would
  # make later installs (e.g. enroot) attempt unwanted downgrades and fail.
  if node.run_state[DRIVER_REPO_ADDED]
    package driver_repo_package_name do
      action local_repo_remove_action
    end

    file driver_repo_package_path do
      action :delete
    end

    action_refresh_metadata
  end

  if node.run_state[CUDA_REPO_ADDED]
    package cuda_repo_package_name do
      action local_repo_remove_action
    end

    file cuda_repo_package_path do
      action :delete
    end

    action_refresh_metadata
  end
end

# ---------------------------------------------------------------------------
# NVIDIA driver local repo
# ---------------------------------------------------------------------------

# Installed name of the NVIDIA driver local-repo package (no revision/arch suffix).
def driver_repo_package_name
  "nvidia-driver-local-repo-#{local_repo_platform}-#{driver_version}"
end

# Local filesystem path of the downloaded driver local-repo installer.
def driver_repo_package_path
  "#{node['cluster']['sources_dir']}/#{driver_repo_package_file}"
end

# Download URL of the driver local-repo installer.
def driver_repo_source_url
  "#{node['cluster']['nvidia']['driver_base_url']}/#{driver_repo_package_file}"
end

# ---------------------------------------------------------------------------
# CUDA local repo
# ---------------------------------------------------------------------------

# Installed name of the CUDA local-repo package (no revision/arch suffix).
def cuda_repo_package_name
  "cuda-repo-#{local_repo_platform}-#{cuda_version_dash(cuda_version)}-local"
end

# Local filesystem path of the downloaded CUDA local-repo installer.
def cuda_repo_package_path
  "#{node['cluster']['sources_dir']}/#{cuda_repo_package_file}"
end

# Download URL of the CUDA local-repo installer.
def cuda_repo_source_url
  "#{node['cluster']['nvidia']['cuda']['base_url']}/#{cuda_repo_package_file}"
end
