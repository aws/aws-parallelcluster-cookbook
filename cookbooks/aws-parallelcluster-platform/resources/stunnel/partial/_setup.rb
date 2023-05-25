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
  stunnel_url = "#{node['cluster']['artifacts_s3_url']}/stunnel/stunnel-#{new_resource.stunnel_version}.tar.gz"
  stunnel_tarball = "#{node['cluster']['sources_dir']}/stunnel-#{new_resource.stunnel_version}.tar.gz"

  # Save stunnel version for InSpec tests
  node.default['cluster']['stunnel']['version'] = new_resource.stunnel_version
  node_attributes 'dump node attributes'

  directory node['cluster']['sources_dir'] do
    recursive true
  end

  package_repos 'update package repositories' do
    action :update
  end

  build_tools 'Prerequisite: build tools'

  # Get dependencies of stunnel
  package dependencies do
    retries 3
    retry_delay 5
  end

  # Get stunnel tarball
  remote_file stunnel_tarball do
    source stunnel_url
    mode '0644'
    retries 3
    retry_delay 5
    checksum new_resource.stunnel_checksum
    action :create_if_missing
  end

  # The installation procedure follows https://docs.aws.amazon.com/efs/latest/ug/upgrading-stunnel.html
  bash "install stunnel" do
    cwd node['cluster']['sources_dir']
    code <<-STUNNELINSTALL
      set -e
      tar xvfz #{stunnel_tarball}
      cd stunnel-#{new_resource.stunnel_version}
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
