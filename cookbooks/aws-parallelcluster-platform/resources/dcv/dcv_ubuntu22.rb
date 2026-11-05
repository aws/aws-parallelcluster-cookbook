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
# See the License for the specific language governing permissions and limitations under the License
provides :dcv, platform: 'ubuntu' do |node|
  node['platform_version'].to_i == 22
end

use 'partial/_dcv_common'
use 'partial/_ubuntu_common'

def dcv_sha256sum
  if arm_instance?
    '91d089e803b64def80c634eb19fe9d54daa3280cfaa7757ca1cb520d468da680'
  else
    '5eff9d47a964e8cd412572ba486f3f38321a1e23943ed0817f5303b285cce00e'
  end
end
