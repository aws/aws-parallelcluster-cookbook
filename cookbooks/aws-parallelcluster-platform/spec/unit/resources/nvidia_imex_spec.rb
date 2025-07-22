require 'spec_helper'

shared_dir = "SHARED_DIR"
nvidia_version = "NVIDIA_VERSION"
nvidia_imex_shared_dir = "#{shared_dir}/nvidia-imex"

class ConvergeNvidiaImex
  def self.install(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      nvidia_imex 'install' do
        action :install
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
      imex_binary = '/usr/bin/nvidia-imex'
      imex_ctl_binary = '/usr/bin/nvidia-imex-ctl'
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

        it 'is false' do
          expect(resource.imex_installed).to eq(false)
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
            allow(res).to receive(:imex_installed).and_return(false)
          end
          runner(platform: platform, version: version, step_into: ['nvidia_imex'])
        end

        before do
          chef_run.node.override['cluster']['shared_dir'] = shared_dir
          chef_run.node.override['cluster']['region'] = 'aws_region'
          chef_run.node.override['cluster']['nvidia']['driver_version'] = nvidia_version
          ConvergeNvidiaImex.install(chef_run)
        end

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
          is_expected.to install_package('nvidia-imex')
            .with(retries: 3)
            .with(retry_delay: 5)
            .with(version: nvidia_version)
        end
      end
    end
  end
end
