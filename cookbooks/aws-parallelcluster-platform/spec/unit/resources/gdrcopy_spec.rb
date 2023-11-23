require 'spec_helper'

class ConvergeGdrcopy
  def self.setup(chef_run, gdrcopy_version: nil, gdrcopy_checksum: nil)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      gdrcopy 'setup' do
        gdrcopy_version gdrcopy_version
        gdrcopy_checksum gdrcopy_checksum
        action :setup
      end
    end
  end

  def self.verify(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      gdrcopy 'verify' do
        action :verify
      end
    end
  end

  def self.configure(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      gdrcopy 'configure' do
        action :configure
      end
    end
  end
end

describe 'gdrcopy:gdrcopy_enabled?' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:sources_dir) { 'sources_dir' }
      cached(:gdrcopy_version) { 'gdrcopy_version' }
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
        runner(platform: platform, version: version, step_into: ['gdrcopy']) do |node|
          node.override['cluster']['sources_dir'] = sources_dir
        end
      end
      cached(:resource) do
        ConvergeGdrcopy.setup(chef_run, gdrcopy_version: gdrcopy_version)
        chef_run.find_resource('gdrcopy', 'setup')
      end

      context 'when nvidia not enabled' do
        it "is not enabled" do
          allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
          expect(resource.gdrcopy_enabled?).to eq(false)
        end
      end

      context 'when nvidia enabled' do
        context 'on arm instance' do
          before do
            allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
            allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
          end

          if platform == 'centos'
            it "is not enabled" do
              expect(resource.gdrcopy_enabled?).to eq(false)
            end
          else
            it "is enabled" do
              expect(resource.gdrcopy_enabled?).to eq(true)
            end
          end
        end
        context 'not on arm instance' do
          it "is enabled" do
            allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
            allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
            expect(resource.gdrcopy_enabled?).to eq(true)
          end
        end
      end
    end
  end
end

describe 'gdrcopy:gdrcopy_arch' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version} - arm" do
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
        runner = runner(platform: platform, version: version, step_into: ['gdrcopy'])
        ConvergeGdrcopy.setup(runner)
      end
      cached(:resource) do
        chef_run.find_resource('gdrcopy', 'setup')
      end

      context 'on arm instance' do
        cached(:expected_arch) do
          case platform
          when 'amazon', 'redhat'
            'aarch64'
          else
            'arm64'
          end
        end

        it 'returns arch value for arm architecture' do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
          expect(resource.gdrcopy_arch).to eq(expected_arch)
        end
      end

      context 'not on arm instance' do
        cached(:expected_arch) do
          platform == 'ubuntu' ? 'amd64' : 'x86_64'
        end

        it 'returns arch value for arm architecture' do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          expect(resource.gdrcopy_arch).to eq(expected_arch)
        end
      end
    end
  end
end

describe 'gdrcopy:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version} when gdrcopy not enabled" do
      cached(:chef_run) do
        stubs_for_resource('gdrcopy') do |res|
          allow(res).to receive(:gdrcopy_enabled?).and_return(false)
        end
        runner = runner(platform: platform, version: version, step_into: ['gdrcopy'])
        ConvergeGdrcopy.setup(runner)
      end

      it 'does not install gdrcopy' do
        is_expected.not_to run_bash('Install NVIDIA GDRCopy')
      end
    end

    context "on #{platform}#{version} when gdrcopy enabled" do
      cached(:sources_dir) { 'sources_dir' }
      cached(:gdrcopy_version) { 'gdrcopy_version' }
      cached(:gdrcopy_checksum) { 'gdrcopy_checksum' }
      cached(:gdrcopy_service) { platform == 'ubuntu' ? 'gdrdrv' : 'gdrcopy' }
      cached(:gdrcopy_tarball) { "#{sources_dir}/gdrcopy-#{gdrcopy_version}.tar.gz" }
      cached(:gdrcopy_url) { "https://github.com/NVIDIA/gdrcopy/archive/refs/tags/v#{gdrcopy_version}.tar.gz" }
      cached(:gdrcopy_dependencies) do
        case platform
        when 'ubuntu'
          %w(build-essential devscripts debhelper check libsubunit-dev fakeroot pkg-config dkms)
        else
          %w(dkms rpm-build make check check-devel subunit subunit-devel)
        end
      end
      cached(:gdrcopy_arch) { 'gdrcopy_arch' }
      cached(:gdrcopy_platform) do
        platforms = {
          'amazon2' => 'amzn-2',
          'centos7' => '.el8',
          'rhel8' => '.el7',
          'ubuntu20.04' => 'Ubuntu20_04',
          'ubuntu22.04' => 'Ubuntu22_04',
        }
        platforms["#{platform}#{version}"]
      end
      cached(:chef_run) do
        stubs_for_resource('gdrcopy') do |res|
          allow(res).to receive(:gdrcopy_enabled?).and_return(true)
          allow(res).to receive(:gdrcopy_arch).and_return(gdrcopy_arch)
        end
        runner = runner(platform: platform, version: version, step_into: ['gdrcopy']) do |node|
          node.override['cluster']['sources_dir'] = sources_dir
        end
        ConvergeGdrcopy.setup(runner, gdrcopy_version: gdrcopy_version, gdrcopy_checksum: gdrcopy_checksum)
      end
      cached(:node) { chef_run.node }

      it 'sets up gdrcopy' do
        is_expected.to setup_gdrcopy('setup')
      end

      it 'shares gdrcopy service and version with InSpec tests' do
        expect(node['cluster']['nvidia']['gdrcopy']['version']).to eq(gdrcopy_version)
        expect(node['cluster']['nvidia']['gdrcopy']['service']).to eq(gdrcopy_service)
        is_expected.to write_node_attributes('dump node attributes')
      end

      it 'downloads gdrcopy tarball' do
        is_expected.to create_if_missing_remote_file(gdrcopy_tarball).with(
          source: gdrcopy_url,
          mode: '0644',
          retries: 3,
          retry_delay: 5,
          checksum: gdrcopy_checksum
        )
      end

      it 'builds dependencies' do
        is_expected.to install_package(gdrcopy_dependencies).with_retries(3).with_retry_delay(5)
      end

      cached(:installation_code) { chef_run.bash('Install NVIDIA GDRCopy').code }

      it 'installs NVIDIA GDRCopy' do
        is_expected.to run_bash('Install NVIDIA GDRCopy').with(
          user: 'root',
          group: 'root',
          cwd: Chef::Config[:file_cache_path]
        ).with_code(/tar -xf #{gdrcopy_tarball}/)
                                                         .with_code(%r{cd gdrcopy-#{gdrcopy_version}/packages})

        if platform == 'ubuntu'
          expect(installation_code).to match(%r{CUDA=/usr/local/cuda ./build-deb-packages.sh})
          expect(installation_code).to match(/dpkg -i gdrdrv-dkms_#{gdrcopy_version}-1_#{gdrcopy_arch}.#{gdrcopy_platform}.deb/)
          expect(installation_code).to match(/dpkg -i libgdrapi_#{gdrcopy_version}-1_#{gdrcopy_arch}.#{gdrcopy_platform}.deb/)
          expect(installation_code).to match(/dpkg -i gdrcopy-tests_#{gdrcopy_version}-1_#{gdrcopy_arch}.#{gdrcopy_platform}\+cuda\*.deb/)
          expect(installation_code).to match(/dpkg -i gdrcopy_#{gdrcopy_version}-1_#{gdrcopy_arch}.#{gdrcopy_platform}.deb/)
        else
          expect(installation_code).to match(%r{CUDA=/usr/local/cuda ./build-rpm-packages.sh})
          expect(installation_code).to match(/rpm -q gdrcopy-kmod-#{gdrcopy_version}-1dkms || rpm -Uvh gdrcopy-kmod-#{gdrcopy_version}-1dkms.#{gdrcopy_platform}.noarch.rpm/)
          expect(installation_code).to match(/rpm -q gdrcopy-#{gdrcopy_version}-1.#{gdrcopy_arch} || rpm -Uvh gdrcopy-#{gdrcopy_version}-1.#{gdrcopy_platform}.#{gdrcopy_arch}.rpm/)
          expect(installation_code).to match(/rpm -q gdrcopy-devel-#{gdrcopy_version}-1.noarch || rpm -Uvh gdrcopy-devel-#{gdrcopy_version}-1.#{gdrcopy_platform}.noarch.rpm/)
        end
      end

      it 'disables gdrcopy service' do
        is_expected.to disable_service(gdrcopy_service).with_action(%i(disable stop))
      end
    end
  end
end

describe 'gdrcopy:verify' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['gdrcopy'])
        ConvergeGdrcopy.verify(runner)
      end

      it 'verifies gdrcopy' do
        is_expected.to verify_gdrcopy('verify')
        is_expected.to run_bash("Verify NVIDIA GDRCopy: copybw").with(
          user: 'root',
          group: 'root',
          cwd: Chef::Config[:file_cache_path]
        ).with_code(/copybw/)
      end
    end
  end
end

describe 'gdrcopy:configure' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:gdrcopy_service) { platform == 'ubuntu' ? 'gdrdrv' : 'gdrcopy' }
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:graphic_instance?).and_return(true)
        allow_any_instance_of(Object).to receive(:is_service_installed?).with(gdrcopy_service).and_return(true)
        runner = runner(platform: platform, version: version, step_into: ['gdrcopy'])
        ConvergeGdrcopy.configure(runner)
      end

      it 'configures gdrcopy' do
        is_expected.to configure_gdrcopy('configure')
      end

      it 'enables gdrcopy service' do
        is_expected.to run_execute("enable #{gdrcopy_service} service").with_command("systemctl enable #{gdrcopy_service}")
      end

      it 'starts gdrcopy service' do
        is_expected.to start_service(gdrcopy_service).with_supports({ status: true })
      end
    end
  end
end
