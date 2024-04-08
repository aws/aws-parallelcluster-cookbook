# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

provides :slurm_dependencies, platform: 'amazon' do |node|
  node['platform_version'].to_i == 2023
end

use 'partial/_slurm_dependencies_common'

def dependencies
  %w(json-c-devel perl perl-Switch lua-devel dbus-devel)
end

action :install_extra_dependencies do
  # http parser is no longer maintained, therefore Amazon Linux 2023 does have have the package in OS repos
  # https://docs.aws.amazon.com/linux/al2023/release-notes/removed-AL2023.4-AL2.html
  # Following https://slurm.schedmd.com/related_software.html#jwt for Installing Http-parser
  bash 'Install http-parser' do
    code <<-HTTP_PARSER
    set -e
    git clone --depth 1 --single-branch -b v2.9.4 https://github.com/nodejs/http-parser.git http_parser
    cd http_parser
    make
    make install
    HTTP_PARSER
  end
end
