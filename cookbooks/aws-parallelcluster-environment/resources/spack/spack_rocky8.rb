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

provides :spack, platform: 'rocky' do |node|
  node['platform_version'].to_i >= 8
end

use 'partial/_spack_common.rb'

def dependencies
  %w(autoconf automake bison byacc cscope ctags diffstat doxygen elfutils flex gcc gcc-c++ gcc-gfortran git
     indent intltool libtool patch patchutils rcs rpm-build rpm-sign subversion swig system-rpm-config systemtap
     curl findutils hostname iproute redhat-lsb-core python3 python3-setuptools unzip python3-boto3)
end

def libfabric_path
  '/opt/amazon/efa/lib64/pkgconfig/libfabric.pc'
end

action :setup do
  action_install_spack
end
