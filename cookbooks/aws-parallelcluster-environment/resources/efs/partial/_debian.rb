# frozen_string_literal: true

#
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

def install_script_code(efs_utils_tarball, efs_utils_package, efs_utils_version)
  <<-EFSUTILSINSTALL
      set -e
      tar xf #{efs_utils_tarball}
      cd efs-utils-#{efs_utils_version}
      ./build-deb.sh
      apt-get -y install ./build/#{efs_utils_package}*deb
  EFSUTILSINSTALL
end

def prerequisites
  %w(dkms)
end
