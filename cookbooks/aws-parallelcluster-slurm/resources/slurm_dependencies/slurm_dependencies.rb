# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

provides :slurm_dependencies
unified_mode true

default_action :setup

package_dependencies = value_for_platform(
  'ubuntu' => {
    'default' => %w(libjson-c-dev libhttp-parser-dev libswitch-perl),
  },
  'default' => %w(json-c-devel http-parser-devel perl-Switch)
)

action :setup do
  package package_dependencies do
    flush_cache({ before: true }) unless platform?('ubuntu') # not supported by apt

    retries 3
    retry_delay 5
  end
end
