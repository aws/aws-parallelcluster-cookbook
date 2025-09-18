require 'spec_helper'

cluster_artifacts_s3_url = 'https://aws_region-aws-parallelcluster.s3.AWS_REGION.AWS_DOMAIN'
source_dir = 'SOURCE_DIR'
arch_suffix_rhel = {
  'x86_64' => 'x86_64',
  'aarch64' => 'aarch64',
}.freeze
arch_suffix_debian = {
  'x86_64' => 'amd64',
  'aarch64' => 'arm64',
}.freeze

class ConvergeNvidiaNvlsm
  def self.install(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      nvidia_nvlsm 'install' do
        action :install
      end
    end
  end
end

describe 'nvidia_nvlsm:nvlsm_installation_enabled?' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version, step_into: ['nvidia_nvlsm'])
      end
      cached(:resource) do
        ConvergeNvidiaNvlsm.install(chef_run)
        chef_run.find_resource('nvidia_nvlsm', 'install')
      end

      if "#{platform}#{version}" == 'amazon2'
        it 'on Amazon Linux 2, nvlsm installation is disabled' do
          expect(resource.nvlsm_installation_enabled?).to eq(false)
        end
      else
        context "when nvidia is not enabled" do
          before do
            allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
          end

          it 'nvlsm installation is disabled' do
            expect(resource.nvlsm_installation_enabled?).to eq(false)
          end
        end

        context "when nvlsm is already installed" do
          before do
            allow(File).to receive(:exist?).with('/opt/nvidia/nvlsm/sbin/nvlsm').and_return(true)
          end

          it 'nvlsm installation is disabled' do
            expect(resource.nvlsm_installation_enabled?).to eq(false)
          end
        end

        context "when nvlsm is already installed" do
          before do
            allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
          end

          it 'nvlsm installation is disabled' do
            expect(resource.nvlsm_installation_enabled?).to eq(false)
          end
        end

        context "when nvlsm installation is disabled via chef attribute" do
          cached(:chef_run) do
            runner(platform: platform, version: version) do |node|
              node.override['cluster']['nvidia']['nvlsm']['enabled'] = false
            end
          end

          it 'nvlsm installation is disabled' do
            expect(resource.nvlsm_installation_enabled?).to eq(false)
          end
        end
      end
    end
  end
end

describe 'nvidia_nvlsm:install' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'when nvlsm installation is disabled' do
        cached(:chef_run) do
          stubs_for_resource('nvidia_nvlsm') do |res|
            allow(res).to receive(:nvlsm_installation_enabled?).and_return(false)
          end
          runner = runner(platform: platform, version: version, step_into: ['nvidia_nvlsm'])
          ConvergeNvidiaNvlsm.install(runner)
        end
        cached(:node) { chef_run.node }

        it 'does not install nvlsm' do
          is_expected.not_to run_bash("Install nvlsm")
        end
      end

      %w(x86_64 aarch64).each do |arch|
        context "when nvlsm installation is enabled on #{arch}" do
          cached(:chef_run) do
            stubs_for_resource('nvidia_nvlsm') do |res|
              allow(res).to receive(:nvlsm_installation_enabled?).and_return(true)
            end
            runner = runner(platform: platform, version: version, step_into: ['nvidia_nvlsm']) do |node|
              node.override['cluster']['artifacts_s3_url'] = cluster_artifacts_s3_url
              node.override['cluster']['sources_dir'] = source_dir
              node.automatic['kernel']['machine'] = arch
            end
            ConvergeNvidiaNvlsm.install(runner)
          end
          cached(:node) { chef_run.node }

          cached(:nvlsm_version) { "2025.03.9-1" }
          cached(:nvlsm_package_full_name) do
            if %(redhat rocky amazon).include?(platform)
              "nvlsm-#{nvlsm_version}.#{arch_suffix_rhel[arch]}.rpm"
            else
              "nvlsm_#{nvlsm_version}_#{arch_suffix_debian[arch]}.deb"
            end
          end
          cached(:nvlsm_checksum) do
            if %(redhat rocky amazon).include?(platform)
              if arch == 'aarch64'
                'f21f14843c11ce64136fd1c3fa763b7511e18f160695f54b2a8d763776313539'
              else
                '88d5e52183bb5ee763eb864bbd119b591e7f45af32c52bd7ba0aa8f74fc19057'
              end
            elsif arch == 'aarch64'
              '6bb405a3494d9fcb6dad6e641d02afb71fd4e2f6a2b4ed3d5cf6cbff22964eb3'
            else
              '61f280e469624c43eecb0e08305452887e02f73e4763252a41f728d1843f1cc5'
            end
          end
          cached(:nvlsm_url) do
            os_directory = if platform == 'amazon'
                             "amzn#{version}"
                           elsif %(redhat rocky).include?(platform)
                             "rhel#{version}"
                           else
                             "#{platform}#{version.delete('.')}"
                           end
            "#{cluster_artifacts_s3_url}/dependencies/nvidia_nvlsm/#{os_directory}/#{nvlsm_package_full_name}"
          end

          cached(:nvlsm_installation_commands) do
            if %(redhat rocky amazon).include?(platform)
              "    set -ex\n    yum install -y #{nvlsm_package_full_name} && yum versionlock nvlsm\n"
            else
              "    set -ex\n    dpkg -i #{nvlsm_package_full_name} && apt-mark hold nvlsm\n"
            end
          end
          cached(:nvlsm_dependencies_installation_commands) do
            if %(redhat rocky amazon).include?(platform)
              "    set -ex\n    yum install -y infiniband-diags libibumad\n"
            else
              "    set -ex\n    apt install -y infiniband-diags ibutils\n"
            end
          end

          it 'installs dependencies of nvlsm' do
            is_expected.to run_bash("Install nvlsm dependencies").with(
              user: 'root',
              retries: 3,
              retry_delay: 5,
              code: nvlsm_dependencies_installation_commands
            )
          end

          it 'configures infiniband kernel module to be loaded at boot time' do
            is_expected.to create_cookbook_file('/etc/modules-load.d/parallelcluster-infiniband.conf').with(
              source: 'infiniband/infiniband.conf',
              user: 'root',
              group: 'root',
              mode: '0644'
            )
          end

          it 'downloads nvlsm' do
            is_expected.to create_if_missing_remote_file("#{source_dir}/#{nvlsm_package_full_name}").with(
              source: nvlsm_url,
              checksum: nvlsm_checksum,
              mode: '0644',
              retries: 3,
              retry_delay: 5
            )
          end

          it 'installs nvlsm' do
            is_expected.to run_bash("Install nvlsm").with(
              user: 'root',
              cwd: source_dir,
              retries: 3,
              retry_delay: 5,
              code: nvlsm_installation_commands
            )
          end
        end
      end
    end
  end
end
