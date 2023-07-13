# frozen_string_literal: true

# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

provides :spack, platform: 'ubuntu', platform_version: '22.04'

use 'partial/_spack_common.rb'

def dependencies
  %w(build-essential ca-certificates coreutils curl environment-modules gfortran git gpg
     lsb-release python3 python3-distutils python3-venv unzip zip)
end

def libfabric_path
  '/opt/amazon/efa/lib/pkgconfig/libfabric.pc'
end


action :install_spack do
  action_install_spack_common

  # Spack does not properly set paths when it finds both gcc11 and gcc12 in /usr/bin
  replace_or_add 'fix gcc12 cxx path' do
    path "#{node['cluster']['spack']['root']}/etc/spack/compilers.yaml"
    pattern '      cxx: null'
    line '      cxx: /usr/bin/g++'
    replace_only true
  end

  replace_or_add 'fix gcc12 f77 path' do
    path "#{node['cluster']['spack']['root']}/etc/spack/compilers.yaml"
    pattern '      f77: null'
    line '      f77: /usr/bin/g++'
    replace_only true
  end

  replace_or_add 'fix gcc12 fc path' do
    path "#{node['cluster']['spack']['root']}/etc/spack/compilers.yaml"
    pattern '      fc: null'
    line '      fc: /usr/bin/g++'
    replace_only true
  end
end
