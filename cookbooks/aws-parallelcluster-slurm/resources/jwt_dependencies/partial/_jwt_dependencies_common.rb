# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

unified_mode true
default_action :setup

action :setup do
  package_repos 'update package repos' do
    action :update
  end

  install_packages 'jwt dependencies' do
    packages dependencies
    action :install
  end unless redhat_ubi?
end

def dependencies
  %w(jansson-devel)
end
