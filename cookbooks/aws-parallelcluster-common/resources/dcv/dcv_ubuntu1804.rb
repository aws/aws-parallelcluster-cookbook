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
provides :dcv, platform: 'ubuntu', platform_version: '18.04'

use 'partial/_dcv_common'
use 'partial/_debian_common'

action_class do
  def dcv_sha256sum
    if arm_instance?
      "aba52420ead3cf05e547b410a479d920696144ddc2529ce7d562960747a6b1e5"
    else
      "c4390d87e3aa75cf163d1b7782d901019e7216a5a9aa466d582aa3415075b1ec"
    end
  end
end
