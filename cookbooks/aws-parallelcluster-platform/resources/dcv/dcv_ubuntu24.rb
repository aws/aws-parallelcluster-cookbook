# frozen_string_literal: true

#
# Copyright:: 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
  node['platform_version'].to_i == 24
end

use 'partial/_dcv_common'
use 'partial/_ubuntu_common'

def dcv_sha256sum
  if arm_instance?
    '8010ea95cfa6b11c2904e37ad50bd1d7d19040f2631eca9099a023e65aa7c65e'
  else
    '4694071af44270952e375aceeddf402e90aaa110b2c586ae973aa3e503d907e7'
  end
end
