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

# Skip Docker — Grubby is not installed; so no real kernel cmdline to modify.
# Skip Debian/Ubuntu — they use AppArmor by default and do not ship SELinux.
# packages/policies, so this recipe is a no-op there.
return if on_docker? || platform_family?('debian')

# Persist SELINUX=disabled to /etc/selinux/config. Honored on RHEL 8 / Rocky 8
# (kernel 4.18); silently ignored on kernels >= 6.4 (AL2023 6.12, RHEL 9 / Rocky 9 - 5.14).
# See: https://github.com/SELinuxProject/selinux-kernel/wiki/DEPRECATE-runtime-disable
selinux_state "SELinux Disabled" do
  action :disabled
  only_if 'which getenforce'
end

# Disable SELinux on the kernel cmdline via grubby — the kernel-recommended
# method that works on all RHEL-family kernels.
execute 'disable selinux via grubby' do
  command 'grubby --update-kernel=ALL --args="selinux=0"'
  not_if 'grubby --info=ALL | grep -q "selinux=0"'
end

# Persist selinux=0 in /etc/default/grub so the setting survives any later
# grub2-mkconfig regeneration and kernel updates that create new BLS entries.
# Required on AL2023 / RHEL8 x86_64 (c_states regenerates BLS) and on all
# OSes long-term (kernel updates create new BLS entries from this template).

# Replace selinux=1 with selinux=0 if present (AL2023, RHEL/Rocky 8).
execute 'replace selinux=1 in /etc/default/grub' do
  command 'sed -i -E \'/^GRUB_CMDLINE_LINUX(_DEFAULT)?=/ s/selinux=1/selinux=0/g\' /etc/default/grub'
  only_if 'grep -qE "^GRUB_CMDLINE_LINUX(_DEFAULT)?=.*selinux=1" /etc/default/grub'
end

# Append selinux=0 if no selinux= is present on the line (Rocky9).
execute 'append selinux=0 to /etc/default/grub' do
  command 'sed -i -E \'/^GRUB_CMDLINE_LINUX(_DEFAULT)?=/ {/selinux=/!s/"$/ selinux=0"/}\' /etc/default/grub'
  not_if 'grep -qE "^GRUB_CMDLINE_LINUX(_DEFAULT)?=.*selinux=" /etc/default/grub'
end
