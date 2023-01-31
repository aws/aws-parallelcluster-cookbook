# frozen_string_literal: true

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

provides :c_states, platform: 'amazon', platform_version: '2'
unified_mode true
default_action :setup

action :setup do
  return if !x86? || docker?

  grub_cmdline_attributes = {
    "processor.max_cstate" => { "value" => "1" },
    "intel_idle.max_cstate" => { "value" => "1" },
  }

  # Amazon Linux 2 name for grub kernel arguments is GRUB_CMDLINE_LINUX_DEFAULT
  append_if_not_present_grub_cmdline(grub_cmdline_attributes, 'GRUB_CMDLINE_LINUX_DEFAULT')

  execute "Regenerate grub boot menu" do
    command '/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg'
  end
end
