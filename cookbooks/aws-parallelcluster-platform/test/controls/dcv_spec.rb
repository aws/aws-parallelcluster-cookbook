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

control 'tag:install_dcv_connect_script_installed' do
  title 'Check pcluster dcv connect script is installed'
  only_if { !os_properties.redhat_on_docker? }

  describe file("#{node['cluster']['scripts_dir']}/pcluster_dcv_connect.sh") do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 0755 }
  end
end

control 'tag:install_dcv_authenticator_user_and_group_set_up' do
  title 'Check that dcv authenticator user and group have been set up'
  only_if { !os_properties.redhat_on_docker? && !(os_properties.ubuntu? && os_properties.arm?) && !os_properties.alinux2023? }

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

control 'tag:install_dcv_disabled_lock_screen' do
  title 'Check that the lock screen has been disabled'
  only_if { !os_properties.redhat_on_docker? && !(os_properties.ubuntu? && os_properties.arm?) && !os_properties.alinux2023? }

  describe bash('gsettings get org.gnome.desktop.lockdown disable-lock-screen') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /true/ }
  end

  describe bash('gsettings get org.gnome.desktop.screensaver lock-enabled') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /false/ }
  end
end

control 'tag:install_dcv_installed' do
  title 'Check dcv is installed'
  only_if { !os_properties.redhat_on_docker? && !(os_properties.ubuntu? && os_properties.arm?) && !os_properties.alinux2023? }

  pkgs = %W(nice-dcv-server nice-xdcv nice-dcv-web-viewer)
  pkgs.each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end
end

control 'tag:install_dcv_external_authenticator_virtualenv_created' do
  title 'Check dcv external authenticator virtual environment is created'
  only_if { !os_properties.redhat_on_docker? && !(os_properties.ubuntu? && os_properties.arm?) && !os_properties.alinux2023? }

  describe file("#{node['cluster']['dcv']['authenticator']['virtualenv_path']}/bin/activate") do
    it { should be_file }
    its('owner') { should eq('root') }
  end
end

control 'tag:install_dcv_debian_specific_setup' do
  title 'Check debian specific setup'
  only_if { os_properties.debian_family? && !(os_properties.ubuntu? && os_properties.arm?) && !os_properties.alinux2023? }

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

control 'tag:install_dcv_rhel_and_centos_specific_setup' do
  title 'Check rhel and centos specific setup'
  only_if { !os_properties.on_docker? }
  only_if { !os_properties.alinux2023? }
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

  # Verify Bridge Network Interface is present.
  # It's provided by libvirt-daemon, installed as requirement for gnome-boxes, included in @gnome.
  # Open MPI does not ignore other local-only devices other than loopback:
  # if virtual bridge interface is up, Open MPI assumes that that network is usable for MPI communications.
  # This is incorrect and it led to MPI applications hanging when they tried to send or receive MPI messages
  # see https://www.open-mpi.org/faq/?category=tcp#tcp-selection for details
  describe bash("[ $(brctl show | awk 'FNR == 2 {print $1}') ] && exit 1 || exit 0") do
    its('exit_status') { should eq 0 }
  end

  # As in the disable_selinux_spec we would need to skip testing that selinux is disabled
  # in centos and redhat because there we would need a reboot. As these are the two OSs that
  # we test in this control, we simply omit that check.
end

control 'tag:install_dcv_alinux2_specific_setup' do
  title 'Check alinux2 specific setup'

  only_if { os_properties.alinux2? }

  prereq_packages = %w(gdm gnome-session gnome-classic-session gnome-session-xsession
                       xorg-x11-server-Xorg xorg-x11-fonts-Type1 xorg-x11-drivers
                       gnu-free-fonts-common gnu-free-mono-fonts gnu-free-sans-fonts
                       gnu-free-serif-fonts glx-utils) + (os_properties.arm? ? %w(mate-terminal) : %w(gnome-terminal))

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

control 'tag:install_dcv_switch_runlevel_to_multiuser_target' do
  title 'Check that runlevel is switched to multi-user.target'
  only_if { !os_properties.on_docker? }
  only_if { !os_properties.alinux2023? }

  describe bash('systemctl get-default') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /multi-user.target/ }
  end
end

control 'tag:config_dcv_external_authenticator_user_and_group_correctly_defined' do
  only_if { instance.dcv_installed? && !os_properties.redhat_on_docker? }
  describe user(node['cluster']['dcv']['authenticator']['user']) do
    it { should exist }
    its('uid') { should eq node['cluster']['dcv']['authenticator']['user_id'] }
    its('gid') { should eq node['cluster']['dcv']['authenticator']['group_id'] }
    # 'NICE DCV External Authenticator user'
  end

  describe group(node['cluster']['dcv']['authenticator']['group']) do
    it { should exist }
    its('gid') { should eq node['cluster']['dcv']['authenticator']['group_id'] }
  end
end

control 'tag:config_expected_versions_of_nice-dcv-gl_installed' do
  only_if do
    instance.head_node? && instance.dcv_installed? && node['cluster']['dcv_enabled'] == "head_node" &&
      instance.graphic? && instance.nvidia_installed? && instance.dcv_gpu_accel_supported? && !os_properties.redhat_on_docker?
  end

  describe package('nice-dcv-gl') do
    it { should be_installed }
    its('version') { should match /#{node['cluster']['dcv']['gl']['version']}/ }
  end
end

control 'tag:config_dcv_correctly_installed' do
  only_if do
    instance.head_node? && instance.dcv_installed? && !os_properties.redhat_on_docker?
  end

  describe bash("sudo -u #{node['cluster']['cluster_user']} dcv version") do
    its('exit_status') { should eq(0) }
  end

  describe bash("#{node['cluster']['dcv']['authenticator']['virtualenv_path']}/bin/python -V") do
    its('stdout') { should match /Python #{node['cluster']['python-version']}/ }
  end unless os_properties.on_docker?

  describe 'check screensaver screen lock disabled' do
    subject { bash('gsettings get org.gnome.desktop.screensaver lock-enabled') }
    its('stdout') { should match /false/ }
  end

  describe 'check non-screensaver screen lock disabled' do
    subject { bash('gsettings get org.gnome.desktop.lockdown disable-lock-screen') }
    its('stdout') { should match /true/ }
  end
end

control 'tag:config_dcv_correctly_configured' do
  only_if { instance.head_node? && instance.dcv_installed? && node['cluster']['dcv_enabled'] == "head_node" && !os_properties.on_docker? }

  describe file('/etc/dcv/dcv.conf') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 0755 }
  end

  describe directory('/var/spool/parallelcluster/pcluster_dcv_authenticator') do
    it { should exist }
    it { should be_owned_by "#{node['cluster']['dcv']['authenticator']['user']}" }
    it { should be_mode 01733 }
  end

  describe file("#{node['cluster']['dcv']['authenticator']['user_home']}/pcluster_dcv_authenticator.py") do
    it { should exist }
    it { should be_file }
    it { should be_owned_by "#{node['cluster']['dcv']['authenticator']['user']}" }
    it { should be_mode 0700 }
  end

  describe file("#{node['cluster']['etc_dir']}/generate_certificate.sh") do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_mode 0700 }
  end

  describe file("#{node['cluster']['dcv']['authenticator']['certificate']}") do
    it { should exist }
    it { should be_file }
    it { should be_owned_by "#{node['cluster']['dcv']['authenticator']['user']}" }
    it { should be_grouped_into 'dcv' }
    it { should be_mode 0440 }
  end

  describe file("#{node['cluster']['dcv']['authenticator']['private_key']}") do
    it { should exist }
    it { should be_file }
    it { should be_owned_by "#{node['cluster']['dcv']['authenticator']['user']}" }
    it { should be_grouped_into 'dcv' }
    it { should be_mode 0440 }
  end
end

control 'tag:config_dcv_services_correctly_configured' do
  only_if { !os_properties.redhat_on_docker? }
  if instance.head_node? && instance.dcv_installed? && node['cluster']['dcv_enabled'] == "head_node"
    describe service('dcvserver') do
      it { should be_installed }
      it { should be_enabled }
      it { should be_running }
    end unless os_properties.on_docker?

    describe bash('systemctl get-default') do
      its('exit_status') { should eq 0 }
      its('stdout') { should match /graphical.target/ }
    end unless os_properties.on_docker?

    if os_properties.debian_family?
      describe file('/etc/ssl/openssl.conf') do
        its('content') { should_not match /RANDFILE/ }
      end
    end

    if instance.graphic? && instance.nvidia_installed? && instance.dcv_gpu_accel_supported?
      describe 'Ensure local users can access X server (dcv-gl must be installed)' do
        subject { command %?DISPLAY=:0 XAUTHORITY=$(ps aux | grep "X.*\-auth" | grep -v grep | sed -n 's/.*-auth \([^ ]\+\).*/\1/p') xhost | grep "LOCAL:$"? }
        its('exit_status') { should eq(0) }
      end
    end

    if os_properties.alinux2?
      describe service('gdm') do
        it { should be_installed }
        it { should be_enabled }
        it { should be_running }
      end
    end

  else
    describe bash('systemctl get-default') do
      its('exit_status') { should eq 0 }
      its('stdout') { should match /multi-user.target/ }
    end

    if os_properties.alinux2?
      describe service('gdm') do
        it { should be_installed }
        it { should be_enabled }
        it { should_not be_running }
      end
    end
  end
end
