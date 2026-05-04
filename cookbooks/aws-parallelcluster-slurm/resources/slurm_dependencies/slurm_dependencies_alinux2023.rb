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

http_parser_version = "2.9.4"
http_parser_url = "#{node['cluster']['artifacts_s3_url']}/dependencies/http_parser/v#{http_parser_version}.tar.gz"
http_parser_tarball = "#{node['cluster']['sources_dir']}/http-parser-#{http_parser_version}.tar.gz"

def dependencies
  %w(json-c-devel perl perl-Switch lua-devel dbus-devel)
end

action :install_extra_dependencies do
  # http parser is no longer maintained, therefore Amazon Linux 2023 does not have the package in OS repos
  # https://docs.aws.amazon.com/linux/al2023/release-notes/removed-AL2023.4-AL2.html
  # Following https://slurm.schedmd.com/related_software.html#jwt for Installing Http-parser.
  # We install into /usr (LIBDIR=/usr/lib64) so the shared library lands in the dynamic linker's
  # default search path.

  remote_file "#{http_parser_tarball}" do
    source "#{http_parser_url}"
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  bash 'make install' do
    user 'root'
    group 'root'
    cwd "#{node['cluster']['sources_dir']}"
    code <<-HTTP
      set -e
      tar xf #{http_parser_tarball}
      cd http-parser-#{http_parser_version}
      make
      make install PREFIX=/usr LIBDIR=/usr/lib64
      ldconfig
    HTTP
  end
end
