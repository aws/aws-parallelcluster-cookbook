require 'spec_helper'

class ConvergeDcv
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      dcv 'setup' do
        action :setup
      end
    end
  end

  def self.configure(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      dcv 'configure' do
        action :configure
      end
    end
  end

  def self.nothing(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      dcv 'nothing' do
        action :nothing
      end
    end
  end
end

describe 'dcv:dcv_supported?' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version, step_into: ['dcv'])
      end
      cached(:resource) do
        ConvergeDcv.nothing(chef_run)
        chef_run.find_resource('dcv', 'nothing')
      end

      context 'when on arm' do
        before do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
        end

        if platform == 'ubuntu' && version.to_i >= 20
          it "is false" do
            expect(resource.dcv_supported?).to eq(false)
          end
        else
          it "is true" do
            expect(resource.dcv_supported?).to eq(true)
          end
        end

        it 'executes nothing action of dcv resource' do
          is_expected.to nothing_dcv('nothing')
        end
      end

      context 'when not on arm' do
        it "is true" do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          expect(resource.dcv_supported?).to eq(true)
        end
      end
    end
  end
end

describe 'dcv:dcv_*_arch' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version, step_into: ['dcv'])
      end
      cached(:resource) do
        ConvergeDcv.nothing(chef_run)
        chef_run.find_resource('dcv', 'nothing')
      end

      context 'when on arm' do
        before do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
        end

        it 'returns arm architecture' do
          expect(resource.dcv_pkg_arch).to eq('arm64')
          expect(resource.dcv_url_arch).to eq('aarch64')
        end
      end

      context 'when not on arm' do
        before do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
        end

        it "returns x86_64" do
          expect(resource.dcv_pkg_arch).to eq('amd64')
          expect(resource.dcv_url_arch).to eq('x86_64')
        end
      end
    end
  end
end

describe 'dcv:packages' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:dcv_version) { 'dcv_version-patch' }
      cached(:dcv_server_version) { 'dcv_server_version' }
      cached(:dcv_webviewer_version) { 'dcv_webviewer_version' }
      cached(:dcv_gl_version) { 'dcv_gl_version' }
      cached(:xdcv_version) { 'xdcv_version' }
      cached(:dcv_url_arch) { 'url_arch' }
      cached(:dcv_pkg_arch) { 'pkg_arch' }
      cached(:base_os) { 'base_os' }

      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
        stubs_for_resource('dcv') do |res|
          allow(res).to receive(:dcv_url_arch).and_return(dcv_url_arch)
          allow(res).to receive(:dcv_pkg_arch).and_return(dcv_pkg_arch)
        end
        runner(platform: platform, version: version, step_into: ['dcv']) do |node|
          node.override['cluster']['dcv']['version'] = dcv_version
          node.override['cluster']['dcv']['server']['version'] = dcv_server_version
          node.override['cluster']['dcv']['xdcv']['version'] = xdcv_version
          node.override['cluster']['dcv']['web_viewer']['version'] = dcv_webviewer_version
          node.override['cluster']['dcv']['gl']['version'] = dcv_gl_version
          node.override['cluster']['base_os'] = base_os
        end
      end
      cached(:resource) do
        ConvergeDcv.nothing(chef_run)
        chef_run.find_resource('dcv', 'nothing')
      end

      it 'sets dcv packages' do
        if platform == 'ubuntu'
          expect(resource.dcv_package).to eq("nice-dcv-#{dcv_version}-#{base_os}-#{dcv_url_arch}")
          expect(resource.dcv_server).to eq("nice-dcv-server_#{dcv_server_version}_#{dcv_pkg_arch}.#{base_os}.deb")
          expect(resource.xdcv).to eq("nice-xdcv_#{xdcv_version}_#{dcv_pkg_arch}.#{base_os}.deb")
          expect(resource.dcv_web_viewer).to eq("nice-dcv-web-viewer_#{dcv_webviewer_version}_#{dcv_pkg_arch}.#{base_os}.deb")
          expect(resource.dcv_gl).to eq("/nice-dcv-gl_#{dcv_gl_version}_#{dcv_pkg_arch}.#{base_os}.deb")
        else
          dcv_platform_version = platform == "amazon" ? "7" :  version.to_i
          expect(resource.dcv_package).to eq("nice-dcv-#{dcv_version}-el#{dcv_platform_version}-#{dcv_url_arch}")
          expect(resource.dcv_server).to eq("nice-dcv-server-#{dcv_server_version}.el#{dcv_platform_version}.#{dcv_url_arch}.rpm")
          expect(resource.xdcv).to eq("nice-xdcv-#{xdcv_version}.el#{dcv_platform_version}.#{dcv_url_arch}.rpm")
          expect(resource.dcv_web_viewer).to eq("nice-dcv-web-viewer-#{dcv_webviewer_version}.el#{dcv_platform_version}.#{dcv_url_arch}.rpm")
          expect(resource.dcv_gl).to eq("nice-dcv-gl-#{dcv_gl_version}.el#{dcv_platform_version}.#{dcv_url_arch}.rpm")
        end
      end
    end
  end
end

describe 'dcv:dcv_gpu_accel_supported?' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
        runner(platform: platform, version: version, step_into: ['dcv'])
      end
      cached(:node) { chef_run.node }
      cached(:resource) do
        ConvergeDcv.nothing(chef_run)
        chef_run.find_resource('dcv', 'nothing')
      end

      context 'when not graphic instance' do
        before do
          allow_any_instance_of(Object).to receive(:graphic_instance?).and_return(false)
        end

        it 'returns false' do
          expect(resource.dcv_gpu_accel_supported?).to eq(false)
        end
      end

      context 'when graphic instance' do
        before do
          allow_any_instance_of(Object).to receive(:graphic_instance?).and_return(true)
        end

        context 'and nvidia not installed' do
          before do
            allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(false)
          end

          it 'returns false' do
            expect(resource.dcv_gpu_accel_supported?).to eq(false)
          end
        end

        context 'and nvidia installed' do
          before do
            allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(true)
          end

          context('and instance type is g5g') do
            before { node.override['ec2']['instance_type'] = 'g5g.any' }
            it 'returns false' do
              expect(resource.dcv_gpu_accel_supported?).to eq(false)
            end
          end

          context('and instance type is not g5g') do
            before { node.override['ec2']['instance_type'] = 'c5c.any' }
            it 'returns true' do
              expect(resource.dcv_gpu_accel_supported?).to eq(true)
            end
          end
        end
      end
    end
  end
end

describe 'dcv:dcv_url' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:dcv_major_minor) { 'major.minor' }
      cached(:dcv_version) { "#{dcv_major_minor}-patch" }
      cached(:dcv_package) { "dcv_package" }
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
        runner(platform: platform, version: version, step_into: ['dcv']) do |node|
          node.override['cluster']['dcv']['version'] = dcv_version
        end
      end
      cached(:node) { chef_run.node }
      cached(:resource) do
        stubs_for_resource('dcv') do |res|
          allow(res).to receive(:dcv_package).and_return(dcv_package)
        end
        ConvergeDcv.nothing(chef_run)
        chef_run.find_resource('dcv', 'nothing')
      end

      it 'returns dcv_url' do
        expect(resource.dcv_url).to eq("https://d1uj6qtbmh3dt5.cloudfront.net/#{dcv_major_minor}/Servers/#{dcv_package}.tgz")
      end
    end
  end
end

describe 'dcv:dcv_tarball' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:sources_dir) { 'sources_dir' }
      cached(:dcv_version) { "dcv_version" }
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
        runner(platform: platform, version: version, step_into: ['dcv']) do |node|
          node.override['cluster']['sources_dir'] = sources_dir
          node.override['cluster']['dcv']['version'] = dcv_version
        end
      end
      cached(:node) { chef_run.node }
      cached(:resource) do
        ConvergeDcv.nothing(chef_run)
        chef_run.find_resource('dcv', 'nothing')
      end

      it 'returns dcv_tarball' do
        expect(resource.dcv_tarball).to eq("#{sources_dir}/dcv-#{dcv_version}.tgz")
      end
    end
  end
end

describe 'dcv:dcvauth_virtualenv' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:system_pyenv_root) { 'system_pyenv_root' }
      cached(:python_version) { "python_version" }
      cached(:virtualenv) { 'dcv_authenticator_virtualenv' }
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
        runner(platform: platform, version: version, step_into: ['dcv']) do |node|
          node.override['cluster']['system_pyenv_root'] = system_pyenv_root
          node.override['cluster']['python-version'] = python_version
        end
      end
      cached(:node) { chef_run.node }
      cached(:resource) do
        ConvergeDcv.nothing(chef_run)
        chef_run.find_resource('dcv', 'nothing')
      end

      it 'sets dcvauth virtualenv' do
        expect(resource.dcvauth_virtualenv).to eq(virtualenv)
        expect(resource.dcvauth_virtualenv_path).to eq("#{node['cluster']['system_pyenv_root']}/versions/#{python_version}/envs/#{virtualenv}")
      end
    end
  end
end

describe 'dcv:prereq_packages on amazon linux' do
  cached(:chef_run) do
    runner(platform: 'amazon', version: '2', step_into: ['dcv'])
  end
  cached(:resource) do
    ConvergeDcv.nothing(chef_run)
    chef_run.find_resource('dcv', 'nothing')
  end
  cached(:common_prereq_packages) do
    %w(gdm gnome-session gnome-classic-session gnome-session-xsession
                         xorg-x11-server-Xorg xorg-x11-fonts-Type1 xorg-x11-drivers
                         gnu-free-fonts-common gnu-free-mono-fonts gnu-free-sans-fonts
                         gnu-free-serif-fonts glx-utils)
  end

  context 'when on arm' do
    before do
      allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
    end

    it 'returns prereq package list with mate-terminal' do
      expect(resource.prereq_packages).to eq(common_prereq_packages + %w(mate-terminal))
    end
  end

  context 'when not on arm' do
    before do
      allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
    end

    it 'returns prereq package list with gnome-terminal' do
      expect(resource.prereq_packages).to eq(common_prereq_packages + %w(gnome-terminal))
    end
  end
end

describe 'dcv:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:scripts_dir) { 'scripts_dir' }
      cached(:sources_dir) { 'sources_dir' }
      cached(:authenticator_group) { 'authenticator_group' }
      cached(:authenticator_group_id) { 'authenticator_group_id' }
      cached(:authenticator_user) { 'authenticator_user' }
      cached(:authenticator_user_id) { 'authenticator_user_id' }
      cached(:authenticator_user_home) { 'authenticator_user_home' }
      cached(:dcv_version) { 'dcv_version' }
      cached(:dcv_server_version) { 'dcv_server_version' }
      cached(:dcv_webviewer_version) { 'dcv_webviewer_version' }
      cached(:xdcv_version) { 'xdcv_version' }
      cached(:dcv_tarball) { 'dcv_tarball' }
      cached(:base_os) { 'base_os' }
      cached(:checksum) { 'checksum' }
      cached(:system_pyenv_root) { 'system_pyenv_root' }
      cached(:python_version) { 'python-version' }
      cached(:alinux_prereq_packages) { 'alinux_prereq_packages' }
      cached(:dcv_url_arch) { 'dcv_url_arch' }
      cached(:dcv_pkg_arch) { 'dcv_pkg_arch' }
      cached(:dcv_package) { 'dcv_package' }
      cached(:dcv_server)  { 'dcv_server' }
      cached(:xdcv) { 'xdcv' }
      cached(:dcv_web_viewer) { 'dcv_web_viewer' }
      cached(:dcv_url) { 's3://dcv_url' }
      cached(:dcvauth_virtualenv) { 'dcvauth_virtualenv' }
      cached(:dcvauth_virtualenv_path) { 'dcvauth_virtualenv_path' }

      cached(:node_setup) do
        lambda { |node|
          node.override['cluster']['sources_dir'] = sources_dir
          node.override['cluster']['scripts_dir'] = scripts_dir
          node.override['cluster']['dcv']['authenticator']['group'] = authenticator_group
          node.override['cluster']['dcv']['authenticator']['group_id'] = authenticator_group_id
          node.override['cluster']['dcv']['authenticator']['user'] = authenticator_user
          node.override['cluster']['dcv']['authenticator']['user_id'] = authenticator_user_id
          node.override['cluster']['dcv']['authenticator']['user_home'] = authenticator_user_home
          node.override['cluster']['dcv']['version'] = dcv_version
          node.override['cluster']['is_official_ami_build'] = true
          node.override['cluster']['system_pyenv_root'] = 'system_pyenv_root'
          node.override['cluster']['python-version'] = 'python-version'
        }
      end
      cached(:res_setup) do
        lambda { |res|
          allow(res).to receive(:dcv_sha256sum).and_return(checksum)
          allow(res).to receive(:dcv_supported?).and_return(true)
          allow(res).to receive(:prereq_packages).and_return(alinux_prereq_packages) if platform == 'amazon'
          allow(res).to receive(:dcv_package).and_return(dcv_package)
          allow(res).to receive(:dcv_server).and_return(dcv_server)
          allow(res).to receive(:xdcv).and_return(xdcv)
          allow(res).to receive(:dcv_web_viewer).and_return(dcv_web_viewer)
          allow(res).to receive(:dcv_url_arch).and_return(dcv_url_arch)
          allow(res).to receive(:dcv_pkg_arch).and_return(dcv_pkg_arch)
          allow(res).to receive(:dcv_url).and_return(dcv_url)
          allow(res).to receive(:dcv_tarball).and_return(dcv_tarball)
          allow(res).to receive(:dcvauth_virtualenv).and_return(dcvauth_virtualenv)
          allow(res).to receive(:dcvauth_virtualenv_path).and_return(dcvauth_virtualenv_path)
        }
      end
      cached(:method_setup) do
        lambda {
          stub_command('which getenforce').and_return(true)
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          allow(::File).to receive(:exist?).with('/etc/dcv/dcv.conf').and_return(false)
          allow(::File).to receive(:exist?).with(dcv_tarball).and_return(false)
        }
      end

      context "when dcv supported" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['dcv']) do |node|
            node_setup.call(node)
          end
          stubs_for_resource('dcv') do |res|
            allow(res).to receive(:dcv_sha256sum).and_return(checksum)
            allow(res).to receive(:dcv_supported?).and_return(true)
            allow(res).to receive(:prereq_packages).and_return(alinux_prereq_packages) if platform == 'amazon'
            allow(res).to receive(:dcv_package).and_return(dcv_package)
            allow(res).to receive(:dcv_server).and_return(dcv_server)
            allow(res).to receive(:xdcv).and_return(xdcv)
            allow(res).to receive(:dcv_web_viewer).and_return(dcv_web_viewer)
            allow(res).to receive(:dcv_url_arch).and_return(dcv_url_arch)
            allow(res).to receive(:dcv_pkg_arch).and_return(dcv_pkg_arch)
            allow(res).to receive(:dcv_url).and_return(dcv_url)
            allow(res).to receive(:dcv_tarball).and_return(dcv_tarball)
            allow(res).to receive(:dcvauth_virtualenv).and_return(dcvauth_virtualenv)
            allow(res).to receive(:dcvauth_virtualenv_path).and_return(dcvauth_virtualenv_path)
          end
          method_setup.call

          ConvergeDcv.setup(runner)
        end
        cached(:node) { chef_run.node }

        it 'sets up dcv' do
          is_expected.to setup_dcv('setup')
        end

        it 'creates directories' do
          is_expected.to create_directory(scripts_dir).with_recursive(true)
          is_expected.to create_directory(sources_dir).with_recursive(true)
        end

        it 'installs pcluster_dcv_connect.sh script to use it for error handling' do
          is_expected.to create_if_missing_cookbook_file("#{scripts_dir}/pcluster_dcv_connect.sh").with(
            source: 'dcv/pcluster_dcv_connect.sh',
            owner: 'root',
            group: 'root',
            mode: '0755'
          )
        end

        it 'sets up dcv authenticator group' do
          is_expected.to create_group(authenticator_group).with(
            comment: 'NICE DCV External Authenticator group',
            gid: authenticator_group_id,
            system: true
          )
        end

        it 'sets up dcv authenticator user' do
          is_expected.to create_user(authenticator_user).with(
            comment: 'NICE DCV External Authenticator user',
            gid: authenticator_group_id,
            uid: authenticator_user_id,
            manage_home: true,
            home: authenticator_user_home,
            system: true,
            shell: '/bin/bash'
          )
        end

        it 'installs prerequisites' do
          case platform
          when 'ubuntu'
            is_expected.to periodic_apt_update('')
            is_expected.to run_bash('install pre-req').with_cwd(Chef::Config[:file_cache_path]).with_retries(10).with_retry_delay(5)
                                                      .with_code(/apt -y install whoopsie/)
                                                      .with_code(/apt -y install ubuntu-desktop && apt -y install mesa-utils || (dpkg --configure -a && exit 1)/)
                                                      .with_code(/apt -y purge ifupdown/)
                                                      .with_code(%r{wget https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY})
          when 'amazon'
            is_expected.to install_package(alinux_prereq_packages).with_retries(10).with_retry_delay(5)
            is_expected.to create_file('Setup Gnome standard').with(
              content: "PREFERRED=/usr/bin/gnome-session",
              owner: "root",
              group: "root",
              mode: "0755",
              path: "/etc/sysconfig/desktop"
            )
          else
            is_expected.to run_execute('Install gnome desktop').with_command('yum -y install @gnome').with_retries(3).with_retry_delay(5)
            is_expected.to install_package('xorg-x11-server-Xorg').with_retries(3).with_retry_delay(5)
            is_expected.to disable_service('libvirtd').with_action(%i(disable stop))
          end
        end

        it 'disables lock screen' do
          is_expected.to create_cookbook_file('/usr/share/glib-2.0/schemas/10_org.gnome.desktop.screensaver.gschema.override').with(
            source: 'dcv/10_org.gnome.desktop.screensaver.gschema.override',
            owner: 'root',
            group: 'root',
            mode: '0755'
          )
          is_expected.to run_execute('Compile gsettings schema').with_command('glib-compile-schemas /usr/share/glib-2.0/schemas/')
        end

        it 'downloads DCV packages' do
          is_expected.to create_remote_file(dcv_tarball).with(
            source: dcv_url,
            mode: '0644',
            checksum: checksum,
            retries: 3,
            retry_delay: 5
          )
        end

        it 'extracts DCV packages' do
          is_expected.to run_bash('extract dcv packages').with_cwd(sources_dir).with_code("tar -xvzf #{dcv_tarball}")
        end

        it 'installs server package' do
          pkg = "#{sources_dir}/#{dcv_package}/#{dcv_server}"
          if platform == 'ubuntu'
            is_expected.to run_execute("apt install dcv package #{pkg}").with(
              command: "apt -y install #{pkg}",
              retries: 3,
              retry_delay: 5
            )
          else
            is_expected.to install_package(pkg).with_source(pkg)
          end
        end

        it 'installs xdcv package' do
          pkg = "#{sources_dir}/#{dcv_package}/#{xdcv}"
          if platform == 'ubuntu'
            is_expected.to run_execute("apt install dcv package #{pkg}").with(
              command: "apt -y install #{pkg}",
              retries: 3,
              retry_delay: 5
            )
          else
            is_expected.to install_package(pkg).with_source(pkg)
          end
        end

        it 'installs xdcv package' do
          pkg = "#{sources_dir}/#{dcv_package}/#{dcv_web_viewer}"
          if platform == 'ubuntu'
            is_expected.to run_execute("apt install dcv package #{pkg}").with(
              command: "apt -y install #{pkg}",
              retries: 3,
              retry_delay: 5
            )
          else
            is_expected.to install_package(pkg).with_source(pkg)
          end
        end

        it 'activates python virtual env' do
          is_expected.to run_install_pyenv('pyenv for default python version')

          is_expected.to run_activate_virtual_env(dcvauth_virtualenv).with(
            pyenv_path: dcvauth_virtualenv_path,
            python_version: python_version
          )
        end

        it 'executes postinstall operations' do
          case platform
          when 'redhat', 'centos'
            # stop firewall
            is_expected.to disable_service('firewalld').with_action(%i(disable stop))

            # Disable selinux
            is_expected.to disabled_selinux_state('SELinux Disabled')
          end
        end

        it 'switches runlevel to multi-user.target for official ami' do
          is_expected.to run_execute('set default systemd runlevel to multi-user.target').with_command('systemctl set-default multi-user.target')
        end
      end

      context "when dcv not supported" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['dcv']) do |node|
            node_setup.call(node)
          end
          stubs_for_resource('dcv') do |res|
            allow(res).to receive(:dcv_sha256sum).and_return(checksum)
            allow(res).to receive(:dcv_supported?).and_return(false)
            allow(res).to receive(:prereq_packages).and_return(alinux_prereq_packages) if platform == 'amazon'
            allow(res).to receive(:dcv_package).and_return(dcv_package)
            allow(res).to receive(:dcv_server).and_return(dcv_server)
            allow(res).to receive(:xdcv).and_return(xdcv)
            allow(res).to receive(:dcv_web_viewer).and_return(dcv_web_viewer)
            allow(res).to receive(:dcv_url_arch).and_return(dcv_url_arch)
            allow(res).to receive(:dcv_pkg_arch).and_return(dcv_pkg_arch)
            allow(res).to receive(:dcv_url).and_return(dcv_url)
            allow(res).to receive(:dcv_tarball).and_return(dcv_tarball)
            allow(res).to receive(:dcvauth_virtualenv).and_return(dcvauth_virtualenv)
            allow(res).to receive(:dcvauth_virtualenv_path).and_return(dcvauth_virtualenv_path)
          end
          method_setup.call
          ConvergeDcv.setup(runner)
        end

        it 'dcv not supported' do
          expect(chef_run.find_resource('dcv', 'setup').dcv_supported?).to eq(false)
        end

        it 'installs pcluster_dcv_connect.sh script to use it for error handling' do
          is_expected.to create_if_missing_cookbook_file("#{scripts_dir}/pcluster_dcv_connect.sh")
        end

        it 'does not set up dcv' do
          is_expected.not_to create_group(authenticator_group)
          is_expected.not_to create_user(authenticator_user)
        end

        it 'switches runlevel to multi-user.target for official ami' do
          is_expected.to run_execute('set default systemd runlevel to multi-user.target').with_command('systemctl set-default multi-user.target')
        end
      end

      context "when dcv already installed" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['dcv']) do |node|
            node_setup.call(node)
          end
          stubs_for_resource('dcv') do |res|
            allow(res).to receive(:dcv_sha256sum).and_return(checksum)
            allow(res).to receive(:dcv_supported?).and_return(true)
            allow(res).to receive(:prereq_packages).and_return(alinux_prereq_packages) if platform == 'amazon'
            allow(res).to receive(:dcv_package).and_return(dcv_package)
            allow(res).to receive(:dcv_server).and_return(dcv_server)
            allow(res).to receive(:xdcv).and_return(xdcv)
            allow(res).to receive(:dcv_web_viewer).and_return(dcv_web_viewer)
            allow(res).to receive(:dcv_url_arch).and_return(dcv_url_arch)
            allow(res).to receive(:dcv_pkg_arch).and_return(dcv_pkg_arch)
            allow(res).to receive(:dcv_url).and_return(dcv_url)
            allow(res).to receive(:dcv_tarball).and_return(dcv_tarball)
            allow(res).to receive(:dcvauth_virtualenv).and_return(dcvauth_virtualenv)
            allow(res).to receive(:dcvauth_virtualenv_path).and_return(dcvauth_virtualenv_path)
          end
          method_setup.call
          allow(::File).to receive(:exist?).with('/etc/dcv/dcv.conf').and_return(true)
          ConvergeDcv.setup(runner)
        end

        it 'does not install dcv' do
          is_expected.not_to create_if_missing_cookbook_file("#{scripts_dir}/pcluster_dcv_connect.sh")
          is_expected.not_to create_group(authenticator_group)
          is_expected.not_to create_user(authenticator_user)
          is_expected.not_to run_execute('set default systemd runlevel to multi-user.target')
        end
      end

      context "when not official ami build" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['dcv']) do |node|
            node_setup.call(node)
            node.override['cluster']['is_official_ami_build'] = false
          end
          stubs_for_resource('dcv') do |res|
            allow(res).to receive(:dcv_sha256sum).and_return(checksum)
            allow(res).to receive(:dcv_supported?).and_return(true)
            allow(res).to receive(:prereq_packages).and_return(alinux_prereq_packages) if platform == 'amazon'
            allow(res).to receive(:dcv_package).and_return(dcv_package)
            allow(res).to receive(:dcv_server).and_return(dcv_server)
            allow(res).to receive(:xdcv).and_return(xdcv)
            allow(res).to receive(:dcv_web_viewer).and_return(dcv_web_viewer)
            allow(res).to receive(:dcv_url_arch).and_return(dcv_url_arch)
            allow(res).to receive(:dcv_pkg_arch).and_return(dcv_pkg_arch)
            allow(res).to receive(:dcv_url).and_return(dcv_url)
            allow(res).to receive(:dcv_tarball).and_return(dcv_tarball)
            allow(res).to receive(:dcvauth_virtualenv).and_return(dcvauth_virtualenv)
            allow(res).to receive(:dcvauth_virtualenv_path).and_return(dcvauth_virtualenv_path)
          end
          method_setup.call
          ConvergeDcv.setup(runner)
        end

        it 'does not switch runlevel to multi-user.target' do
          is_expected.not_to run_execute('set default systemd runlevel to multi-user.target')
        end
      end

      context "when dcv tarball exists" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['dcv']) do |node|
            node_setup.call(node)
            node.override['cluster']['is_official_ami_build'] = false
          end
          stubs_for_resource('dcv') do |res|
            allow(res).to receive(:dcv_sha256sum).and_return(checksum)
            allow(res).to receive(:dcv_supported?).and_return(true)
            allow(res).to receive(:prereq_packages).and_return(alinux_prereq_packages) if platform == 'amazon'
            allow(res).to receive(:dcv_package).and_return(dcv_package)
            allow(res).to receive(:dcv_server).and_return(dcv_server)
            allow(res).to receive(:xdcv).and_return(xdcv)
            allow(res).to receive(:dcv_web_viewer).and_return(dcv_web_viewer)
            allow(res).to receive(:dcv_url_arch).and_return(dcv_url_arch)
            allow(res).to receive(:dcv_pkg_arch).and_return(dcv_pkg_arch)
            allow(res).to receive(:dcv_url).and_return(dcv_url)
            allow(res).to receive(:dcv_tarball).and_return(dcv_tarball)
            allow(res).to receive(:dcvauth_virtualenv).and_return(dcvauth_virtualenv)
            allow(res).to receive(:dcvauth_virtualenv_path).and_return(dcvauth_virtualenv_path)
          end
          method_setup.call
          allow(::File).to receive(:exist?).with(dcv_tarball).and_return(true)
          ConvergeDcv.setup(runner)
        end

        it 'does not download and install DCV packages' do
          is_expected.not_to create_remote_file(dcv_tarball)
          is_expected.not_to run_bash('extract dcv packages').with_cwd(sources_dir).with_code("tar -xvzf #{dcv_tarball}")
        end
      end

      context "when virtual env already activated" do
        cached(:chef_run) do
          stubs_for_resource('dcv') do |res|
            allow(res).to receive(:dcv_sha256sum).and_return(checksum)
            allow(res).to receive(:dcv_supported?).and_return(true)
            allow(res).to receive(:prereq_packages).and_return(alinux_prereq_packages) if platform == 'amazon'
            allow(res).to receive(:dcv_package).and_return(dcv_package)
            allow(res).to receive(:dcv_server).and_return(dcv_server)
            allow(res).to receive(:xdcv).and_return(xdcv)
            allow(res).to receive(:dcv_web_viewer).and_return(dcv_web_viewer)
            allow(res).to receive(:dcv_url_arch).and_return(dcv_url_arch)
            allow(res).to receive(:dcv_pkg_arch).and_return(dcv_pkg_arch)
            allow(res).to receive(:dcv_url).and_return(dcv_url)
            allow(res).to receive(:dcv_tarball).and_return(dcv_tarball)
            allow(res).to receive(:dcvauth_virtualenv).and_return(dcvauth_virtualenv)
            allow(res).to receive(:dcvauth_virtualenv_path).and_return(dcvauth_virtualenv_path)
          end
          method_setup.call
          runner = runner(platform: platform, version: version, step_into: ['dcv']) do |node|
            node_setup.call(node)
          end
          allow(::File).to receive(:exist?).with("#{dcvauth_virtualenv_path}/bin/activate").and_return(true)
          ConvergeDcv.setup(runner)
        end

        it 'does not activate dcv authenticator virtual env' do
          is_expected.not_to run_install_pyenv('pyenv for default python version')
          is_expected.not_to run_activate_virtual_env(dcvauth_virtualenv)
        end
      end
    end
  end
end

describe 'dcv:configure' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:sources_dir) { 'sources_dir' }
      cached(:dcv_version) { 'dcv_version' }
      cached(:dcv_gl_version) { 'dcv_gl_version' }
      cached(:dcv_pkg_arch) { 'amd64' }
      cached(:dcv_url_arch) { 'x86_64' }
      cached(:base_os) { 'base_os' }
      cached(:certificate) { 'certificate' }
      cached(:private_key) { 'private_key' }
      cached(:user) { 'user' }
      cached(:user_home) { 'user_home' }
      cached(:dcv_package) { 'dcv_package' }
      cached(:dcv_gl) { 'dcv_gl' }
      cached(:dcvauth_virtualenv_path) { 'dcvauth_virtualenv_path' }
      cached(:node_setup) do
        lambda { |node|
          node.override['ec2']['instance_type'] = 'any'
          node.override['cluster']['sources_dir'] = sources_dir
          node.override['cluster']['node_type'] = 'HeadNode'
          node.override['cluster']['dcv']['gl']['version'] = dcv_gl_version
          node.override['cluster']['base_os'] = base_os
          node.override['cluster']['dcv']['version'] = dcv_version
          node.override['cluster']['dcv']['gl']['version'] = dcv_gl_version
          node.override['cluster']['dcv']['authenticator']['certificate'] = certificate
          node.override['cluster']['dcv']['authenticator']['private_key'] = private_key
          node.override['cluster']['dcv']['authenticator']['user'] = user
          node.override['cluster']['dcv']['authenticator']['user_home'] = user_home
          node.override['cluster']['dcv']['authenticator']['virtualenv_path'] = dcvauth_virtualenv_path
        }
      end

      context "when dcv_gpu_accel_supported" do
        cached(:chef_run) do
          stubs_for_resource('dcv') do |res|
            allow(res).to receive(:dcv_supported?).and_return(true)
            allow(res).to receive(:dcv_gpu_accel_supported?).and_return(true)
            allow(res).to receive(:dcv_package).and_return(dcv_package)
            allow(res).to receive(:dcv_gl).and_return(dcv_gl)
            allow(res).to receive(:dcvauth_virtualenv_path).and_return(dcvauth_virtualenv_path)
          end
          runner = runner(platform: platform, version: version, step_into: ['dcv']) do |node|
            node_setup.call(node)
          end
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          allow_any_instance_of(Object).to receive(:graphic_instance?).and_return(true)
          allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(true)
          ConvergeDcv.configure(runner)
        end
        cached(:node) { chef_run.node }

        it 'configures dcv' do
          is_expected.to configure_dcv('configure')
        end

        it 'sets up Nvidia drivers for X configuration' do
          is_expected.to run_execute('Set up Nvidia drivers for X configuration')
            .with_user('root')
            .with_command('nvidia-xconfig --preserve-busid --enable-all-gpus')
        end

        it 'installs DCV gl' do
          if platform == 'ubuntu'
            is_expected.to run_execute('apt install dcv-gl')
              .with_command("apt -y install #{sources_dir}/#{dcv_package}/#{dcv_gl}")
          else
            is_expected.to install_package("#{sources_dir}/#{dcv_package}/#{dcv_gl}")
              .with_source("#{sources_dir}/#{dcv_package}/#{dcv_gl}")
          end
        end

        # Configure the X server to start automatically when the Linux server boots and start the X server in background
        it 'configures the X server to start automatically when the Linux server boots and start the X server in background' do
          is_expected.to run_bash('Launch X').with_user('root')
                                             .with_code(/systemctl set-default graphical.target/)
                                             .with_code(/systemctl isolate graphical.target &/)
        end

        it 'verifies that the X server is running' do
          is_expected.to run_execute('Wait for X to start').with(
            user: 'root',
            command: "pidof X || pidof Xorg",
            retries: 10,
            retry_delay: 5
          )
        end

        if platform == 'ubuntu'
          it 'disables RNDFILE from openssl to avoid error during certificate generation' do
            is_expected.to run_execute('No RND')
              .with_user('root')
              .with_command("sed --in-place '/RANDFILE/d' /etc/ssl/openssl.cnf")
          end
        end

        it 'installs utility file to generate HTTPs certificates for the DCV external authenticator and generate a new one' do
          is_expected.to create_cookbook_file('/etc/parallelcluster/generate_certificate.sh').with(
            source: 'dcv/generate_certificate.sh',
            owner: 'root',
            mode: '0700'
          )
          is_expected.to run_execute('certificate generation')
            .with_user('root')
            .with_command("/etc/parallelcluster/generate_certificate.sh \"#{certificate}\" \"#{private_key}\" #{user} dcv")
        end

        it 'generates dcv.conf' do
          is_expected.to create_template('/etc/dcv/dcv.conf').with(
            source: 'dcv/dcv.conf.erb',
            owner: 'root',
            group: 'root',
            mode: '0755'
          )
        end

        it 'creates directory for the external authenticator to store access file created by the users' do
          is_expected.to create_directory('/var/spool/parallelcluster/pcluster_dcv_authenticator').with(
            owner: user,
            mode: '1733',
            recursive: true
          )
        end

        it 'installs DCV external authenticator' do
          is_expected.to create_cookbook_file("#{user_home}/pcluster_dcv_authenticator.py").with(
            source: 'dcv/pcluster_dcv_authenticator.py',
            owner: user,
            mode: '0700'
          )
        end

        it 'starts NICE DCV server' do
          is_expected.to enable_service('dcvserver').with_action(%i(enable start))
        end
      end

      context "when g2 instance" do
        cached(:chef_run) do
          stubs_for_resource('dcv') do |res|
            allow(res).to receive(:dcv_supported?).and_return(true)
            allow(res).to receive(:dcv_gpu_accel_supported?).and_return(true)
            allow(res).to receive(:dcv_package).and_return(dcv_package)
            allow(res).to receive(:dcv_gl).and_return(dcv_gl)
          end
          runner = runner(platform: platform, version: version, step_into: ['dcv']) do |node|
            node_setup.call(node)
            node.override['ec2']['instance_type'] = 'g2.any'
          end
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          allow_any_instance_of(Object).to receive(:graphic_instance?).and_return(true)
          allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(true)
          ConvergeDcv.configure(runner)
        end
        cached(:node) { chef_run.node }

        it 'sets up Nvidia drivers for X configuration' do
          is_expected.to run_execute('Set up Nvidia drivers for X configuration')
            .with_user('root')
            .with_command('nvidia-xconfig --preserve-busid --enable-all-gpus --use-display-device=none')
        end
      end

      context "when dcv_gpu_accel not supported" do
        cached(:chef_run) do
          stubs_for_resource('dcv') do |res|
            allow(res).to receive(:dcv_supported?).and_return(true)
            allow(res).to receive(:dcv_gpu_accel_supported?).and_return(false)
            allow(res).to receive(:dcv_package).and_return(dcv_package)
            allow(res).to receive(:dcv_gl).and_return(dcv_gl)
          end
          runner = runner(platform: platform, version: version, step_into: ['dcv']) do |node|
            node.override['ec2']['instance_type'] = 'any'
            node.override['cluster']['sources_dir'] = sources_dir
            node.override['cluster']['node_type'] = 'HeadNode'
            node.override['cluster']['dcv']['gl']['version'] = dcv_gl_version
            node.override['cluster']['base_os'] = base_os
            node.override['cluster']['dcv']['version'] = dcv_version
            node.override['cluster']['dcv']['gl']['version'] = dcv_gl_version
            node.override['cluster']['dcv']['authenticator']['certificate'] = certificate
            node.override['cluster']['dcv']['authenticator']['private_key'] = private_key
            node.override['cluster']['dcv']['authenticator']['user'] = user
            node.override['cluster']['dcv']['authenticator']['user_home'] = user_home
          end
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          allow_any_instance_of(Object).to receive(:graphic_instance?).and_return(true)
          allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(true)
          ConvergeDcv.configure(runner)
        end
        cached(:node) { chef_run.node }

        it 'does not install DCV gl' do
          if platform == 'ubuntu'
            is_expected.not_to run_execute('apt install dcv-gl')
          else
            is_expected.not_to install_package("#{sources_dir}/#{dcv_package}/#{dcv_gl}")
          end
        end

        it 'sets default systemd runlevel to graphical.target' do
          is_expected.to run_bash('set default systemd runlevel to graphical.target')
            .with_user('root')
            .with_code(/systemctl set-default graphical.target/)
            .with_code(/systemctl isolate graphical.target &/)
        end
      end
    end
  end
end
