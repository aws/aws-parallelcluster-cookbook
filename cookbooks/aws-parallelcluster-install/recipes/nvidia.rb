# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: nvidia
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

if node['cluster']['nvidia']['enabled'] == 'yes' || node['cluster']['nvidia']['enabled'] == true

  # Get NVIDIA run file
  nvidia_tmp_runfile = "/tmp/nvidia.run"
  remote_file nvidia_tmp_runfile do
    source node['cluster']['nvidia']['driver_url']
    mode '0755'
    retries 3
    retry_delay 5
    not_if { ::File.exist?('/usr/bin/nvidia-smi') }
  end

  # Make sure nouveau kernel module is unloaded, otherwise installation of NVIDIA driver fails
  kernel_module 'nouveau' do
    action :uninstall
  end

  # Amazon linux 2 with Kernel 5 need to set CC to /usr/bin/gcc10-gcc using dkms override
  if platform?('amazon') && node['kernel']['release'].split('.')[0].to_i == 5
    package "gcc10" do
      retries 10
      retry_delay 5
    end
    cookbook_file 'dkms/nvidia.conf' do
      source 'dkms/nvidia.conf'
      path '/etc/dkms/nvidia.conf'
      owner 'root'
      group 'root'
      mode '0644'
    end
  end

  # Install NVIDIA driver
  bash 'nvidia.run advanced' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-NVIDIA
      set -e
      ./nvidia.run --silent --dkms --disable-nouveau
      rm -f /tmp/nvidia.run
    NVIDIA
    creates '/usr/bin/nvidia-smi'
  end

  # Get CUDA run file
  cuda_tmp_runfile = "/tmp/cuda.run"
  remote_file cuda_tmp_runfile do
    source node['cluster']['nvidia']['cuda_url']
    mode '0755'
    retries 3
    retry_delay 5
    not_if { ::File.exist?("/usr/local/cuda-#{node['cluster']['nvidia']['cuda_version']}") }
  end

  # Install CUDA driver
  bash 'cuda.run advanced' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-CUDA
      set -e
      ./cuda.run --silent --toolkit --samples
      rm -f /tmp/cuda.run
    CUDA
    creates "/usr/local/cuda-#{node['cluster']['nvidia']['cuda_version']}"
  end

  cookbook_file 'blacklist-nouveau.conf' do
    source 'nvidia/blacklist-nouveau.conf'
    path '/etc/modprobe.d/blacklist-nouveau.conf'
    owner 'root'
    group 'root'
    mode '0644'
  end

  if platform?('ubuntu')
    execute 'initramfs to remove nouveau' do
      command 'update-initramfs -u'
      only_if 'lsinitramfs /boot/initrd.img-$(uname -r) | grep nouveau'
    end
  end

  # NVIDIA Fabric Manager not present on ARM
  unless arm_instance?
    # Install NVIDIA Fabric Manager
    repo_domain = "com"
    repo_domain = "cn" if node['cluster']['region'].start_with?("cn-")
    repo_uri = node['cluster']['nvidia']['fabricmanager']['repository_uri'].gsub('_domain_', repo_domain)
    add_package_repository(
      "nvidia-fm-repo",
      repo_uri,
      "#{repo_uri}/#{node['cluster']['nvidia']['fabricmanager']['repository_key']}",
      "/"
    )

    if platform?('ubuntu')
      # For ubuntu, CINC17 apt-package resources need full versions for `version`
      execute "install_fabricmanager_for_ubuntu" do
        command "apt -y install #{node['cluster']['nvidia']['fabricmanager']['package']}=#{node['cluster']['nvidia']['fabricmanager']['version']} "\
                "&& apt-mark hold #{node['cluster']['nvidia']['fabricmanager']['package']}"
        retries 3
        retry_delay 5
      end
    else
      package node['cluster']['nvidia']['fabricmanager']['package'] do
        version node['cluster']['nvidia']['fabricmanager']['version']
        action %i(install lock)
      end
    end

    remove_package_repository("nvidia-fm-repo")
  end

  # NVIDIA GDRCopy
  gdrcopy_version = node['cluster']['nvidia']['gdrcopy']['version']
  gdrcopy_version_extended = "#{node['cluster']['nvidia']['gdrcopy']['version']}-1"
  gdrcopy_tarball = "#{node['cluster']['sources_dir']}/gdrcopy-#{gdrcopy_version}.tar.gz"
  gdrcopy_checksum = node['cluster']['nvidia']['gdrcopy']['sha1']
  gdrcopy_build_dependencies = value_for_platform(
    'ubuntu' => {
      'default' => %w(build-essential devscripts debhelper check libsubunit-dev fakeroot pkg-config dkms),
    },
    'default' => %w(dkms rpm-build make check check-devel subunit subunit-devel)
  )
  gdrcopy_verification_commands = %w(copybw)

  remote_file gdrcopy_tarball do
    source node['cluster']['nvidia']['gdrcopy']['url']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(gdrcopy_tarball) }
  end

  ruby_block "Validate NVIDIA GDRCopy Tarball Checksum" do
    block do
      require 'digest'
      checksum = Digest::SHA1.file(gdrcopy_tarball).hexdigest # nosemgrep
      raise "Downloaded NVIDIA GDRCopy Tarball Checksum #{checksum} does not match expected checksum #{gdrcopy_checksum}" if checksum != gdrcopy_checksum
    end
  end

  package gdrcopy_build_dependencies do
    retries 3
    retry_delay 5
  end

  platform = value_for_platform(
    'ubuntu' => {
      '18.04' => 'Ubuntu18_04',
      '20.04' => 'Ubuntu20_04',
    },
    'amazon' => { 'default' => 'unknown_distro' },
    'default' => '.el7'
  )
  arch = value_for_platform(
    'ubuntu' => { 'default' => arm_instance? ? 'arm64' : 'amd64' },
    'amazon' => { 'default' => arm_instance? ? 'aarch64' : 'x86_64' },
    'default' => arm_instance? ? 'arm64' : 'x86_64'
  )
  installation_code = value_for_platform(
    'ubuntu' => {
      'default' => <<~COMMAND,
        CUDA=/usr/local/cuda ./build-deb-packages.sh
        dpkg -i gdrdrv-dkms_#{gdrcopy_version_extended}_#{arch}.#{platform}.deb
        dpkg -i libgdrapi_#{gdrcopy_version_extended}_#{arch}.#{platform}.deb
        dpkg -i gdrcopy-tests_#{gdrcopy_version_extended}_#{arch}.#{platform}.deb
        dpkg -i gdrcopy_#{gdrcopy_version_extended}_#{arch}.#{platform}.deb
        COMMAND
    },
    'default' => <<~COMMAND
      CUDA=/usr/local/cuda ./build-rpm-packages.sh
      rpm -i gdrcopy-kmod-#{gdrcopy_version_extended}dkms.noarch#{platform}.rpm
      rpm -i gdrcopy-#{gdrcopy_version_extended}.#{arch}#{platform}.rpm
      rpm -i gdrcopy-devel-#{gdrcopy_version_extended}.noarch#{platform}.rpm
      COMMAND
  )

  bash 'Install NVIDIA GDRCopy' do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-GDRCOPY_INSTALL
    set -e
    tar -xf #{gdrcopy_tarball}
    cd gdrcopy-#{gdrcopy_version}/packages
    #{installation_code}
    GDRCOPY_INSTALL
  end

  gdrcopy_verification_commands.each do |command|
    bash "Verify NVIDIA GDRCopy: #{command}" do
      user 'root'
      group 'root'
      cwd Chef::Config[:file_cache_path]
      code <<-GDRCOPY_VERIFY
      set -e
      #{command}
      GDRCOPY_VERIFY
    end
  end

  service node['cluster']['nvidia']['gdrcopy']['service'] do
    action %i(disable stop)
  end
end
