# frozen_string_literal: true
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

unified_mode true
default_action :setup

action :setup do
  action_install_package
end

action :configure do
  enroot_installed = ::File.exist?('/usr/bin/enroot')
  return unless enroot_installed

  bash "Configure enroot" do
    user 'root'
    code <<-ENROOT_CONFIGURE
      set -e
      ENROOT_CONFIG_RELEASE=pyxis
      SHARED_DIR=#{node['cluster']['shared_dir']}
      NONROOT_USER=#{node['cluster']['cluster_user']}
      wget -O /tmp/enroot.template.conf https://raw.githubusercontent.com/aws-samples/aws-parallelcluster-post-install-scripts/${ENROOT_CONFIG_RELEASE}/pyxis/enroot.template.conf
      mkdir -p ${SHARED_DIR}/enroot
      chown ${NONROOT_USER} ${SHARED_DIR}/enroot
      ENROOT_CACHE_PATH=${SHARED_DIR}/enroot envsubst < /tmp/enroot.template.conf > /tmp/enroot.conf
      mv /tmp/enroot.conf /etc/enroot/enroot.conf
      chmod 0644 /etc/enroot/enroot.conf
  
      mkdir -p /tmp/enroot
      chmod 1777 /tmp/enroot
      mkdir -p /tmp/enroot/data
      chmod 1777 /tmp/enroot/data
  
      chmod 1777 ${SHARED_DIR}/enroot
  
      mkdir -p ${SHARED_DIR}/pyxis/
      chown ${NONROOT_USER} ${SHARED_DIR}/pyxis/
      sed -i '${s/$/ runtime_path=${SHARED_DIR}\\/pyxis/}' /opt/slurm/etc/plugstack.conf.d/pyxis.conf
      SHARED_DIR=${SHARED_DIR} envsubst < /opt/slurm/etc/plugstack.conf.d/pyxis.conf > /opt/slurm/etc/plugstack.conf.d/pyxis.tmp.conf
      mv /opt/slurm/etc/plugstack.conf.d/pyxis.tmp.conf /opt/slurm/etc/plugstack.conf.d/pyxis.conf

    ENROOT_CONFIGURE
    retries 3
    retry_delay 5
  end
end

def package_version
  node['cluster']['enroot']['version']
end
