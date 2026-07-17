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
    '770058467e36686e77b4cd6a3d9a953f6714862182e2c9ccd72958d59f35df5b'
  else
    'acfc339c9e57be9800f25734cb18dec87da2b0457b3cfd2582fc57f05de7c792'
  end
end
