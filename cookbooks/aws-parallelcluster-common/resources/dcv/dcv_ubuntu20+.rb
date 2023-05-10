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
  node['platform_version'].to_i >= 20
end

use 'partial/_dcv_common'
use 'partial/_debian_common'

action_class do
  def dcv_sha256sum
    return "6b4c6450bb39f31cb93082a2d1f3977da23d41d3f0646f71b2726e6ba632ea09" if x86?
  end
end
