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
default_action :setup

# Full CUDA toolkit version, e.g. '13.0.2'. The default is lazy so the
# attribute is read at converge time, honoring any override applied after the
# resource class is compiled (e.g. in tests).
property :cuda_version, String, default: lazy { node['cluster']['nvidia']['cuda']['version'] }

action :setup do
  return unless nvidia_enabled?
  return if on_docker?

  # Skip the entire CUDA setup when any CUDA version is already installed
  # (cuda_path is the version-agnostic symlink created by the toolkit).
  return if ::File.exist?(cuda_path)

  # Share CUDA versions with InSpec tests. We expose the major.minor under a
  # dedicated attribute and leave the canonical 'version' attribute as the full
  # version, so other resources (e.g. nvidia_repo) can rely on it regardless of order.
  node.default['cluster']['nvidia']['cuda']['major_minor_version'] = cuda_major_minor
  node.default['cluster']['nvidia']['cuda_samples_version'] = cuda_major_minor
  node_attributes 'Save cuda and cuda samples versions for InSpec tests'

  # Install the CUDA toolkit from the local repo. The built-in `package` resource
  # dispatches to the platform's package manager (dnf on RHEL/Amazon Linux, apt on
  # Ubuntu), so no platform-specific partial is needed. The CUDA local repo, and its
  # refreshed package-manager metadata, is registered earlier in the nvidia install recipe.
  package cuda_toolkit_package do
    retries 3
    retry_delay 5
  end

  # Expose CUDA binaries and libraries to all users
  template '/etc/profile.d/cuda.sh' do
    source 'nvidia/cuda.sh.erb'
    cookbook 'aws-parallelcluster-platform'
    owner 'root'
    group 'root'
    mode '0644'
    variables(cuda_path: cuda_path)
  end

  # Download and unpack the CUDA samples.
  remote_file cuda_samples_archive do
    source cuda_samples_url
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(cuda_samples_dir) }
  end

  bash 'cuda.sample install' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-CUDA
      set -e
      tar xf "#{cuda_samples_archive}" --directory "#{cuda_installation_base_dir}/"
      rm -f "#{cuda_samples_archive}"
    CUDA
    creates cuda_samples_dir
  end
end

# CUDA 'major.minor', e.g. '13.0' for '13.0.2'
def cuda_major_minor
  major, minor = cuda_version.split('.')
  "#{major}.#{minor}"
end

def cuda_toolkit_package
  "cuda-toolkit-#{cuda_version_dash(cuda_version)}"
end

# The CUDA toolkit package installs into a version-specific directory
# (e.g. /usr/local/cuda-13.0) and also creates a version-agnostic '/usr/local/cuda'
# symlink pointing to it. We use the two deliberately for different purposes:
#  - cuda_install_dir: the versioned directory; used to locate the CUDA samples dir.
#  - cuda_path: the stable symlink; used to detect whether any CUDA version is already
#    installed (to skip installation) and injected into /etc/profile.d/cuda.sh so that
#    users' PATH/LD_LIBRARY_PATH keep working across CUDA version changes.

# Version-specific CUDA installation directory, e.g. '/usr/local/cuda-13.0'
def cuda_install_dir
  "#{cuda_installation_base_dir}/cuda-#{cuda_major_minor}"
end

# Directory where the CUDA samples are unpacked, e.g. '/usr/local/cuda-13.0/samples'
def cuda_samples_dir
  "#{cuda_install_dir}/samples"
end

# Version-agnostic CUDA directory, a symlink to the version-specific installation
# directory (cuda_install_dir), e.g. '/usr/local/cuda' -> '/usr/local/cuda-13.0'.
# Injected into /etc/profile.d/cuda.sh.
def cuda_path
  "#{cuda_installation_base_dir}/cuda"
end

# Base directory under which all CUDA software is installed
def cuda_installation_base_dir
  '/usr/local'
end

def cuda_samples_url
  "#{node['cluster']['nvidia']['cuda']['samples_base_url']}/v#{cuda_major_minor}.tar.gz"
end

def cuda_samples_archive
  '/tmp/cuda-sample.tar.gz'
end
