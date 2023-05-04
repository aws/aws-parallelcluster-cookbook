# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

control 'dcv_connect_script_installed' do
  title 'Check pcluster dcv connect script is installed'

  only_if { !os_properties.redhat_ubi? }

  describe file("#{node['cluster']['scripts_dir']}/pcluster_dcv_connect.sh") do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 0755 }
  end
end

control 'dcv_authenticator_user_and_group_set_up' do
  title 'Check that dcv authenticator user and group have been set up'

  only_if { !os_properties.redhat_ubi? }

  describe group(node['cluster']['dcv']['authenticator']['group']) do
    it { should exist }
    its('gid') { should eq node['cluster']['dcv']['authenticator']['group_id'] }
  end

  describe user(node['cluster']['dcv']['authenticator']['user']) do
    it { should exist }
    its('uid') { should eq node['cluster']['dcv']['authenticator']['user_id'] }
    its('gid') { should eq node['cluster']['dcv']['authenticator']['group_id'] }
  end
end

control 'dcv_disabled_lock_screen' do
  title 'Check that the lock screen has been disabled'

  only_if { !os_properties.redhat_ubi? }

  describe bash('gsettings get org.gnome.desktop.lockdown disable-lock-screen') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /true/ }
  end

  describe bash('gsettings get org.gnome.desktop.screensaver lock-enabled') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /false/ }
  end
end

control 'dcv_installed' do
  title 'Check dcv is installed'

  only_if { !os_properties.redhat_ubi? }

  pkgs = %W(nice-dcv-server nice-xdcv nice-dcv-web-viewer)
  pkgs.each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end
end

control 'dcv_external_authenticator_virtualenv_created' do
  title 'Check dcv external authenticator virtual environment is created'

  only_if { !os_properties.redhat_ubi? }

  describe file("#{node['cluster']['dcv']['authenticator']['virtualenv_path']}/bin/activate") do
    it { should be_file }
    its('owner') { should eq('root') }
  end
end

control 'dcv_debian_specific_setup' do
  title 'Check debian specific setup'

  only_if { os_properties.debian_family? }

  pkgs = %W(whoopsie ubuntu-desktop mesa-utils)
  pkgs.each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end

  describe package('ifupdown') do
    it { should_not be_installed }
  end

  describe bash('gpg --list-keys') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /NICE s.r.l./ }
  end
end

control 'dcv_rhel_and_centos_specific_setup' do
  title 'Check rhel and centos specific setup'

  only_if { os_properties.centos? || os_properties.redhat? }

  describe command('gnome-shell --version') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match 'GNOME Shell' }
  end

  describe package('xorg-x11-server-Xorg') do
    it { should be_installed }
  end

  disabled_services = %w(libvirtd firewalld)
  disabled_services.each do |svc|
    describe service(svc) do
      it { should_not be_enabled }
      it { should_not be_running }
    end
  end

  # As in the disable_selinux_spec we would need to skip testing that selinux is disabled
  # in centos and redhat beacuse there we would need a reboot. As these are the two OSs that
  # we test in this control, we simply omit that check.
end

control 'dcv_alinux2_specific_setup' do
  title 'Check alinux2 specific setup'

  only_if { os_properties.alinux2? }

  prereq_packages = %w(gdm gnome-session gnome-classic-session gnome-session-xsession
                       xorg-x11-server-Xorg xorg-x11-fonts-Type1 xorg-x11-drivers
                       gnu-free-fonts-common gnu-free-mono-fonts gnu-free-sans-fonts
                       gnu-free-serif-fonts glx-utils gnome-terminal)

  prereq_packages.each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end

  describe file('/etc/sysconfig/desktop') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 0755 }
    its('content') { should eq 'PREFERRED=/usr/bin/gnome-session' }
  end
end

control 'dcv_switch_runlevel_to_multiuser_target' do
  title 'Check that runlevel is switched to multi-user.target'

  only_if { !os_properties.redhat_ubi? }

  describe bash('systemctl get-default') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /multi-user.target/ }
  end
end
