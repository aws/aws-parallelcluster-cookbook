# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: install_slurm
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

slurm_dependencies 'Install slurm dependencies'

slurm_install_dir = node['cluster']['slurm']['install_dir']

slurm_version = node['cluster']['slurm']['version']
slurm_commit = node['cluster']['slurm']['commit']
slurm_branch = node['cluster']['slurm']['branch']
slurm_tar_name = if !slurm_commit.empty?
                   "#{slurm_commit}"
                 elsif !slurm_branch.empty?
                   "#{slurm_branch}"
                 else
                   "slurm-#{slurm_version}"
                 end
slurm_tarball = "#{node['cluster']['sources_dir']}/#{slurm_tar_name}.tar.gz"
slurm_url = "https://github.com/SchedMD/slurm/archive/#{slurm_tar_name}.tar.gz"
slurm_sha256 = if slurm_branch.empty?
                 node['cluster']['slurm']['sha256']
               end

include_recipe 'aws-parallelcluster-slurm::slurm_users'

# Get slurm tarball
remote_file slurm_tarball do
  source slurm_url
  mode '0644'
  retries 3
  retry_delay 5
  checksum slurm_sha256
  action :create_if_missing
end

# Copy Slurm patches
remote_directory "#{node['cluster']['sources_dir']}/slurm_patches" do
  source 'install_slurm/slurm_patches'
  mode '0755'
  action :create
  recursive true
end

# Copy Slurm patches from S3 if passed via dna.json
if !node['cluster']['slurm_patches_s3_archive'].nil? && !node['cluster']['slurm_patches_s3_archive'].empty?
  remote_object 'Retrieve Custom Slurm Settings' do
    url node['cluster']['slurm_patches_s3_archive']
    destination "#{node['cluster']['sources_dir']}/slurm_patches_from_s3.tar.gz"
    sensitive true
  end

  bash 'extract Slurm patches from archive' do
    user 'root'
    group 'root'
    cwd "#{node['cluster']['sources_dir']}/slurm_patches"
    code <<-UNTAR
    set -e
    tar xf #{node['cluster']['sources_dir']}/slurm_patches_from_s3.tar.gz
    UNTAR
  end
end

# Install Slurm
bash 'make install' do
  not_if { redhat_on_docker? }
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-SLURM
    set -e

    # python3 is required to build slurm >= 20.02
    source #{cookbook_virtualenv_path}/bin/activate

    tar xf #{slurm_tarball}
    cd slurm-#{slurm_tar_name}

    # Apply possible Slurm patches
    shopt -s nullglob  # with this an empty slurm_patches directory does not trigger the loop
    for patch in #{node['cluster']['sources_dir']}/slurm_patches/*.diff; do
      echo "Applying patch ${patch}..."
      patch --ignore-whitespace -p1 < ${patch}
      echo "...DONE."
    done
    shopt -u nullglob

    # Configure Slurm
    ./configure --prefix=#{slurm_install_dir} --with-pmix=/opt/pmix --with-jwt=/opt/libjwt --enable-slurmrestd

    # Build Slurm
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    make install
    make install-contrib

    deactivate
  SLURM
  # TODO: Fix, so it works for upgrade
  creates "#{slurm_install_dir}/bin/srun"
end

# Copy required licensing files
directory "#{node['cluster']['license_dir']}/slurm"

bash 'copy license stuff' do
  not_if { redhat_on_docker? }
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-SLURMLICENSE
    set -e
    cd slurm-#{slurm_tar_name}
    cp -v COPYING #{node['cluster']['license_dir']}/slurm/COPYING
    cp -v DISCLAIMER #{node['cluster']['license_dir']}/slurm/DISCLAIMER
    cp -v LICENSE.OpenSSL #{node['cluster']['license_dir']}/slurm/LICENSE.OpenSSL
    cp -v README.rst #{node['cluster']['license_dir']}/slurm/README.rst
  SLURMLICENSE
  # TODO: Fix, so it works for upgrade
  creates "#{node['cluster']['license_dir']}/slurm/README.rst"
end

file '/etc/ld.so.conf.d/slurm.conf' do
  not_if { redhat_on_docker? }
  content "#{slurm_install_dir}/lib/"
  mode '0744'
end
