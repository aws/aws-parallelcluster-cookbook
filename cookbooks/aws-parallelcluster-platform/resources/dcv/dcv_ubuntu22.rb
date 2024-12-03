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
    '48bb605dbb5f28af79b94de9239a8c3e7811e9e47078d8985d036915f2a34217'
  else
    'b30a57f5029b9d8acb59db9fc72f1dbc7c6a33d76dbbfe02017cec553c5b86f9'
  end
end
