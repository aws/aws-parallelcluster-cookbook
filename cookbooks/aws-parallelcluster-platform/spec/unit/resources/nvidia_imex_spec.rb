require 'spec_helper'

nvidia_version = "1.2.3"
nvidia_imex_shared_dir = "SHARED_DIR/nvidia-imex"
imex_binary = '/usr/bin/nvidia-imex'
imex_ctl_binary = '/usr/bin/nvidia-imex-ctl'

class ConvergeNvidiaImex
  def self.install(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      nvidia_imex 'install' do
        action :install
      end
    end
  end

  def self.configure(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      nvidia_imex 'configure' do
        action :configure
      end
    end
  end
end

describe 'nvidia_imex:nvidia_enabled_or_installed?' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version, step_into: ['nvidia_imex'])
      end
      cached(:resource) do
        ConvergeNvidiaImex.install(chef_run)
        chef_run.find_resource('nvidia_imex', 'install')
      end

      context "when nvidia not enabled and not installed" do
        before do
          allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
          allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(false)
        end

        it 'is false' do
          expect(resource.nvidia_enabled_or_installed?).to eq(false)
        end
      end

      context "when nvidia not enabled but its already installed" do
        before do
          allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
          allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(true)
        end

        it 'is true' do
          expect(resource.nvidia_enabled_or_installed?).to eq(true)
        end
      end

      context "when nvidia is enabled but its not installed" do
        before do
          allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
          allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(false)
        end

        it 'is true' do
          expect(resource.nvidia_enabled_or_installed?).to eq(true)
        end
      end
    end
  end
end

describe 'nvidia_imex:imex_installed' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version, step_into: ['nvidia_imex'])
      end
      cached(:resource) do
        ConvergeNvidiaImex.install(chef_run)
        chef_run.find_resource('nvidia_imex', 'install')
      end

      context "when #{imex_binary} and #{imex_ctl_binary} does not exist" do
        before do
          allow(File).to receive(:exist?).with(imex_ctl_binary).and_return(false)
          allow(File).to receive(:exist?).with(imex_binary).and_return(false)
        end

        if platform == 'amazon' && version == '2'
          it 'is true' do
            expect(resource.imex_installed).to eq(true)
          end
        else
          it 'is false' do
            expect(resource.imex_installed).to eq(false)
          end
        end
      end

      context "when #{imex_binary} and #{imex_ctl_binary} exists" do
        before do
          allow(File).to receive(:exist?).with(imex_ctl_binary).and_return(true)
          allow(File).to receive(:exist?).with(imex_binary).and_return(true)
        end

        it 'is true' do
          expect(resource.imex_installed).to eq(true)
        end
      end

      context "when #{imex_binary} exists and #{imex_ctl_binary} does not exists" do
        before do
          allow(File).to receive(:exist?).with(imex_ctl_binary).and_return(false)
          allow(File).to receive(:exist?).with(imex_binary).and_return(true)
        end

        it 'is true' do
          expect(resource.imex_installed).to eq(true)
        end
      end

      context "when #{imex_binary} does not exists and #{imex_ctl_binary} exists" do
        before do
          allow(File).to receive(:exist?).with(imex_ctl_binary).and_return(true)
          allow(File).to receive(:exist?).with(imex_binary).and_return(false)
        end

        it 'is true' do
          expect(resource.imex_installed).to eq(true)
        end
      end
    end
  end
end

describe 'nvidia_imex:install' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'when nvidia not enabled' do
        cached(:chef_run) do
          stubs_for_resource('nvidia_imex') do |res|
            allow(res).to receive(:nvidia_enabled_or_installed?).and_return(false)
          end
          runner = runner(platform: platform, version: version, step_into: ['nvidia_imex'])
          ConvergeNvidiaImex.install(runner)
        end
        cached(:node) { chef_run.node }

        it 'does not install nvidia-imex' do
          is_expected.not_to install_package('nvidia-imex')
        end
      end

      context 'when nvidia-imex binary already exists' do
        cached(:chef_run) do
          stubs_for_resource('nvidia_imex') do |res|
            allow(res).to receive(:imex_installed).and_return(true)
          end
          runner = runner(platform: platform, version: version, step_into: ['nvidia_imex'])
          ConvergeNvidiaImex.install(runner)
        end
        cached(:node) { chef_run.node }

        it 'does not install nvidia-imex' do
          is_expected.not_to install_package('nvidia-imex')
        end
      end

      context 'when nvidia is enabled' do
        cached(:chef_run) do
          stubs_for_resource('nvidia_imex') do |res|
            allow(res).to receive(:nvidia_enabled_or_installed?).and_return(true)
            allow(File).to receive(:exist?).with(imex_ctl_binary).and_return(false)
            allow(File).to receive(:exist?).with(imex_binary).and_return(false)
          end
          runner(platform: platform, version: version, step_into: ['nvidia_imex'])
        end
        cached(:nvidia_imex_version) { "1.2.3-1" }
        cached(:nvidia_imex_package) { "nvidia-imex-1" }
        cached(:nvidia_imex_name) do
          if %(redhat rocky).include?(platform) || platform == 'amazon' && version == '2023'
            "#{nvidia_imex_package}-#{nvidia_imex_version}"
          else
            "#{nvidia_imex_package}_#{nvidia_imex_version}"
          end
        end
        cached(:node) { chef_run.node }

        before do
          chef_run.node.override['cluster']['nvidia']['imex']['shared_dir'] = nvidia_imex_shared_dir
          chef_run.node.override['cluster']['region'] = 'aws_region'
          chef_run.node.override['cluster']['nvidia']['driver_version'] = nvidia_version
          ConvergeNvidiaImex.install(chef_run)
        end

        if platform == 'amazon' && version == '2'
          it 'does not install nvidia-imex' do
            is_expected.not_to add_nvidia_repo('add nvidia repository')
            is_expected.not_to create_directory(nvidia_imex_shared_dir)
            is_expected.not_to create_template("#{nvidia_imex_shared_dir}/config.cfg")
              .with(source: 'nvidia-imex/nvidia-imex-config.erb')
              .with(user: 'root')
              .with(group: 'root')
              .with(mode: '0755')
            is_expected.not_to create_template("#{nvidia_imex_shared_dir}/nodes_config.cfg")
              .with(source: 'nvidia-imex/nvidia-imex-nodes.erb')
              .with(user: 'root')
              .with(group: 'root')
              .with(mode: '0755')
            is_expected.not_to create_template("/etc/systemd/system/nvidia-imex.service")
              .with(source: 'nvidia-imex/nvidia-imex.service.erb')
              .with(user: 'root')
              .with(group: 'root')
              .with(mode: '0644')
            is_expected.not_to install_install_packages('Install nvidia-imex')
              .with(packages: "#{nvidia_imex_name}")
              .with(action: %i(install))
          end
          it 'does not set nvidia-imex version' do
            expect(node.default['cluster']['nvidia']['imex']['version']).not_to eq(nvidia_imex_version)
            expect(node.default['cluster']['nvidia']['imex']['package']).not_to eq(nvidia_imex_package)
            is_expected.not_to write_node_attributes('dump node attributes')
            is_expected.not_to remove_nvidia_repo('remove nvidia repository')
          end
        else
          it 'installs nvidia-imex' do
            is_expected.to add_nvidia_repo('add nvidia repository')
            is_expected.to create_directory(nvidia_imex_shared_dir)

            is_expected.to create_template("#{nvidia_imex_shared_dir}/config.cfg")
              .with(source: 'nvidia-imex/nvidia-imex-config.erb')
              .with(user: 'root')
              .with(group: 'root')
              .with(mode: '0755')
            is_expected.to create_template("#{nvidia_imex_shared_dir}/nodes_config.cfg")
              .with(source: 'nvidia-imex/nvidia-imex-nodes.erb')
              .with(user: 'root')
              .with(group: 'root')
              .with(mode: '0755')
            is_expected.to create_template("/etc/systemd/system/nvidia-imex.service")
              .with(source: 'nvidia-imex/nvidia-imex.service.erb')
              .with(user: 'root')
              .with(group: 'root')
              .with(mode: '0644')
            if platform == 'ubuntu'
              is_expected.to install_apt_package('Install nvidia-imex')
                .with(package_name: nvidia_imex_package)
                .with(version: nvidia_imex_version)
                .with(retries: 10)
                .with(retry_delay: 5)
            else
              is_expected.to install_install_packages('Install nvidia-imex')
                .with(packages: nvidia_imex_name)
                .with(action: %i(install))
            end
          end
          it 'sets nvidia-imex version' do
            expect(node.default['cluster']['nvidia']['imex']['version']).to eq(nvidia_imex_version)
            expect(node.default['cluster']['nvidia']['imex']['package']).to eq(nvidia_imex_package)
            is_expected.to write_node_attributes('dump node attributes')
            is_expected.to remove_nvidia_repo('remove nvidia repository')
          end
        end
      end
    end
  end
end

describe 'nvidia_imex:configure' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context "when nvidia-imex binary is not installed" do
        cached(:chef_run) do
          stubs_for_resource('nvidia_imex') do |res|
            allow(res).to receive(:imex_installed).and_return(false)
          end
          runner = runner(platform: platform, version: version, step_into: ['nvidia_imex'])
          ConvergeNvidiaImex.configure(runner)
        end
        cached(:node) { chef_run.node }

        it 'does not configure nvidia-imex' do
          is_expected.not_to configure_nvidia_imex('nvidia-imex')
        end
      end

      %w(HeadNode LoginNode ComputeFleet).each do |node_type|
        context "when get_nvswitch_count > 1 on #{node_type} node" do
          cached(:chef_run) do
            stubs_for_provider('nvidia_imex[configure]') do |pro|
              allow(pro).to receive(:imex_installed).and_return(true)
              allow(pro).to receive(:get_device_ids).and_return({ 'gb200' => 'test' })
              allow(pro).to receive(:get_nvswitch_count).with('test').and_return(4)
            end
            runner(platform: platform, version: version, step_into: ['nvidia_imex'])
          end
          cached(:node) { chef_run.node }

          before do
            chef_run.node.override['cluster']['region'] = 'aws_region'
            chef_run.node.override['cluster']['node_type'] = node_type
            ConvergeNvidiaImex.configure(chef_run)
          end

          if (platform == 'amazon' && version == '2') || %w(HeadNode LoginNode).include?(node_type)
            it 'does not configure nvidia-imex' do
              is_expected.not_to start_service('nvidia-imex').with_action(%i(start enable)).with_supports({ status: true })
            end
          else
            it 'it starts nvidia-imex service' do
              is_expected.to start_service('nvidia-imex').with_action(%i(start enable)).with_supports({ status: true })
            end
          end
        end
      end

      context "when get_nvswitch_count <= 1" do
        cached(:chef_run) do
          stubs_for_provider('nvidia_imex[configure]') do |pro|
            allow(pro).to receive(:imex_installed).and_return(true)
            allow(pro).to receive(:get_device_ids).and_return({ 'gb200' => 'test' })
            allow(pro).to receive(:get_nvswitch_count).with('test').and_return(1)
          end
          runner = runner(platform: platform, version: version, step_into: ['nvidia_imex'])
          ConvergeNvidiaImex.configure(runner)
        end
        cached(:node) { chef_run.node }

        before do
          chef_run.node.override['cluster']['region'] = 'aws_region'
        end

        it 'does not configure nvidia-imex' do
          is_expected.not_to start_service('nvidia-imex').with_action(%i(start enable)).with_supports({ status: true })
        end
      end
    end
  end
end
