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
# See the License for the specific language governing permissions and limitations under the License.

action :setup do
  stunnel_tarball = node['cluster']['stunnel']['tarball_path']

  # Get dependencies of stunnel
  package dependencies do
    retries 3
    retry_delay 5
  end

  # Get stunnel tarball
  remote_file stunnel_tarball do
    source node['cluster']['stunnel']['url']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(stunnel_tarball) }
  end

  # Verify tarball
  ruby_block "verify stunnel checksum" do
    block do
      require 'digest'
      checksum = Digest::SHA256.file(stunnel_tarball).hexdigest
      raise "Downloaded stunnel package checksum #{checksum} does not match expected checksum #{node['cluster']['stunnel']['sha256']}" if checksum != node['cluster']['stunnel']['sha256']
    end
  end

  # The installation procedure follows https://docs.aws.amazon.com/efs/latest/ug/upgrading-stunnel.html
  bash "install stunnel" do
    cwd node['cluster']['sources_dir']
    code <<-STUNNELINSTALL
      set -e
      tar xvfz #{stunnel_tarball}
      cd stunnel-#{node['cluster']['stunnel']['version']}
      ./configure
      make
      if [[ -f /bin/stunnel ]]; then
      rm /bin/stunnel
      fi
      make install
      ln -s /usr/local/bin/stunnel /bin/stunnel
    STUNNELINSTALL
  end
end
