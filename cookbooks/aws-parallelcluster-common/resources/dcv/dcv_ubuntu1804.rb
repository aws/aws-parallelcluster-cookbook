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
      "275c79a51a480a46ff2751f87ae6f597f88e5598da147d76cdc09655e24eab78"
    else
      "b3871281c8a1bff57e92cd2188f3051e09978ead2013decc4b6b2a9921ef2689"
    end
  end
end
