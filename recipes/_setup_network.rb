#
# Cookbook Name:: cfncluster
# Recipe:: _setup_network
#
# Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

if node['platform'] == 'ubuntu'
  if node['platform_version'] == "16.04"
    execute 'sed' do
      command "/bin/sed -r -i -e 's/GRUB_CMDLINE_LINUX=\"(.*)\"/GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0\"/' /etc/default/grub"
    end
    execute 'grub_mkconfig' do
      command "grub-mkconfig -o /boot/grub/grub.cfg"
    end
  end
end
