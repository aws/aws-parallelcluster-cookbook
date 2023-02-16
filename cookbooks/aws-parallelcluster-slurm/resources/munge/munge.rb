# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

provides :munge
unified_mode true

default_action :setup

use 'partial/_munge_actions'

action_class do
  def munge_libdir
    value_for_platform(
      'ubuntu' => {
        'default' => '/usr/lib',
      },
      'default' => '/usr/lib64'
    )
  end
end
