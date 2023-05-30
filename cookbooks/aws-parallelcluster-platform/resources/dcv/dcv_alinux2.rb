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
provides :dcv, platform: 'amazon', platform_version: '2'

use 'partial/_dcv_common'
use 'partial/_rhel_common'

def prereq_packages
  # gnome-terminal is not yet available AL2 ARM. Install mate-terminal instead
  # NOTE: installing mate-terminal requires enabling the amazon-linux-extras epel topic
  #       which is done in base_install.
  %w(gdm gnome-session gnome-classic-session gnome-session-xsession
                         xorg-x11-server-Xorg xorg-x11-fonts-Type1 xorg-x11-drivers
                         gnu-free-fonts-common gnu-free-mono-fonts gnu-free-sans-fonts
                         gnu-free-serif-fonts glx-utils) + (arm_instance? ? %w(mate-terminal) : %w(gnome-terminal))
end

action_class do
  def pre_install
    package prereq_packages do
      retries 10
      retry_delay 5
    end

    # Use Gnome in place of Gnome-classic
    file "Setup Gnome standard" do
      content "PREFERRED=/usr/bin/gnome-session"
      owner "root"
      group "root"
      mode "0755"
      path "/etc/sysconfig/desktop"
    end
  end
end
