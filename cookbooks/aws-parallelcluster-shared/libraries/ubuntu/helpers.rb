# frozen_string_literal: true

# Copyright:: 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

def gcc_major_version_used_by_kernel
  # Detects the gcc major version used to compile the kernel, e.g. 12.
  # If the version cannot be detected, nil is returned.
  # (Tested only on Ubuntu)
  begin
    gcc_major_version = shell_out("cat /proc/version | grep -Eo 'gcc-[0-9]+' | cut -d '-' -f 2").stdout.strip
  rescue => error
    Chef::Log.error("Cannot detect gcc version used to compile the kernel: #{error}")
    return ""
  end
  Chef::Log.info("Detected version of gcc used to compile the kernel is: #{gcc_major_version}")
  gcc_major_version
end
