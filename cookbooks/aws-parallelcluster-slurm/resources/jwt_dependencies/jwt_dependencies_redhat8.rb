# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

provides :jwt_dependencies, platform: 'redhat' do |node|
  node['platform_version'].to_i == 8
end

unified_mode true

default_action :setup

action :setup do
  package 'jansson-devel' do
    flush_cache({ before: true })

    retries 3
    retry_delay 5
  end unless redhat_ubi?
end
