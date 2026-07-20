require 'spec_helper'

nvidia_imex_dir = "/etc/nvidia-imex"
imex_main_conf_file = "#{nvidia_imex_dir}/config.cfg"
imex_nodes_conf_file = "#{nvidia_imex_dir}/nodes_config.cfg"
imex_service_file = "/etc/systemd/system/nvidia-imex.service"
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

  def self.create_configuration_files(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      nvidia_imex 'create_configuration_files' do
        action :create_configuration_files
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

      context "when nvidia is enabled and installed" do
        before do
          allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
          allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(true)
        end

        it 'is true' do
          expect(resource.nvidia_enabled_or_installed?).to eq(true)
        end
      end
    end
  end
end

describe 'nvidia_imex:imex_installed?' do
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

        it 'is false' do
          expect(resource.imex_installed?).to eq(false)
        end
      end

      context "when #{imex_binary} and #{imex_ctl_binary} exists" do
        before do
          allow(File).to receive(:exist?).with(imex_ctl_binary).and_return(true)
          allow(File).to receive(:exist?).with(imex_binary).and_return(true)
        end

        it 'is true' do
          expect(resource.imex_installed?).to eq(true)
        end
      end

      context "when #{imex_binary} exists and #{imex_ctl_binary} does not exists" do
        before do
          allow(File).to receive(:exist?).with(imex_ctl_binary).and_return(false)
          allow(File).to receive(:exist?).with(imex_binary).and_return(true)
        end

        it 'is true' do
          expect(resource.imex_installed?).to eq(true)
        end
      end

      context "when #{imex_binary} does not exists and #{imex_ctl_binary} exists" do
        before do
          allow(File).to receive(:exist?).with(imex_ctl_binary).and_return(true)
          allow(File).to receive(:exist?).with(imex_binary).and_return(false)
        end

        it 'is true' do
          expect(resource.imex_installed?).to eq(true)
        end
      end
    end
  end
end

describe 'nvidia_imex:enable_force_configuration?' do
  [['false', false], [false, false], ['no', false], ['true', true], [true, true], ['yes', true]].each do |force_indicator, actual_indicator|
    context "where node['cluster']['nvidia']['imex']['force_configuration'] is #{force_indicator}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(step_into: ['nvidia_imex']) do |node|
          node.override['cluster']['nvidia']['imex']['force_configuration'] = force_indicator
        end
      end
      cached(:resource) do
        ConvergeNvidiaImex.configure(chef_run)
        chef_run.find_resource('nvidia_imex', 'configure')
      end
      it "we get #{actual_indicator}" do
        allow_any_instance_of(Object).to receive(:enable_force_configuration?).and_return(actual_indicator)
        expect(resource.enable_force_configuration?).to eq(actual_indicator)
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
            allow(res).to receive(:nvidia_enabled_or_installed?).and_return(true)
            allow(res).to receive(:imex_installed?).and_return(true)
          end
          runner = runner(platform: platform, version: version, step_into: ['nvidia_imex'])
          ConvergeNvidiaImex.install(runner)
        end
        cached(:node) { chef_run.node }

        it 'does not install nvidia-imex' do
          is_expected.not_to install_package('nvidia-imex')
        end
      end

      %w(aarch64 x86_64).each do |arm_or_x86|
        context "when nvidia is enabled on #{arm_or_x86}" do
          cached(:nvidia_imex_package) { "nvidia-imex" }

          cached(:chef_run) do
            stubs_for_resource('nvidia_imex') do |res|
              allow(res).to receive(:nvidia_enabled_or_installed?).and_return(true)
              allow(File).to receive(:exist?).with(imex_ctl_binary).and_return(false)
              allow(File).to receive(:exist?).with(imex_binary).and_return(false)
            end
            runner(platform: platform, version: version, step_into: ['nvidia_imex'])
          end
          cached(:node) { chef_run.node }

          before do
            chef_run.node.override['cluster']['region'] = 'aws_region'
            chef_run.node.automatic['kernel']['machine'] = arm_or_x86
            ConvergeNvidiaImex.install(chef_run)
          end

          it 'installs nvidia-imex from nvidia repo' do
            is_expected.to install_package(nvidia_imex_package)
              .with(retries: 3)
              .with(retry_delay: 5)
          end

          it 'locks the package version' do
            if %w(ubuntu).include?(platform)
              is_expected.to run_execute("apt-mark hold #{nvidia_imex_package}")
                .with(retries: 3)
                .with(retry_delay: 5)
            else
              is_expected.to install_package('yum-plugin-versionlock')
              is_expected.to run_execute("yum versionlock #{nvidia_imex_package}")
                .with(retries: 3)
                .with(retry_delay: 5)
            end
          end
        end
      end
    end
  end
end

describe 'nvidia_imex:create_configuration_files' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['nvidia_imex'])
        ConvergeNvidiaImex.create_configuration_files(runner)
      end
      cached(:node) { chef_run.node }

      it 'does create Imex configuration files' do
        is_expected.to create_template("#{imex_nodes_conf_file}")
          .with(source: 'nvidia-imex/nvidia-imex-nodes.erb')
          .with(user: 'root')
          .with(group: 'root')
          .with(mode: '0755')
        is_expected.to create_template("#{imex_main_conf_file}")
          .with(source: 'nvidia-imex/nvidia-imex-config.erb')
          .with(user: 'root')
          .with(group: 'root')
          .with(mode: '0755')
          .with(variables: { imex_nodes_config_file_path: "#{imex_nodes_conf_file}" })
        is_expected.to create_template(imex_service_file)
          .with(source: 'nvidia-imex/nvidia-imex.service.erb')
          .with(user: 'root')
          .with(group: 'root')
          .with(mode: '0644')
          .with(variables: { imex_main_config_file_path: "#{imex_main_conf_file}" })
      end
    end
  end
end

describe 'nvidia_imex:configure' do
  [%w(false), [false], %w(no), %w(true), [true], %w(yes)].each do |force_indicator|
    for_all_oses do |platform, version|
      context "on #{platform}#{version} with force_configuration #{force_indicator}" do
        context "when nvidia-imex binary is not installed" do
          cached(:chef_run) do
            stubs_for_resource('nvidia_imex') do |res|
              allow(res).to receive(:imex_installed?).and_return(false)
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
          context "when is_gb200_node? is true on #{node_type} node" do
            cached(:chef_run) do
              stubs_for_provider('nvidia_imex[configure]') do |pro|
                allow(pro).to receive(:imex_installed?).and_return(true)
                allow(pro).to receive(:is_gb200_node?).and_return(true)
                allow(pro).to receive(:enable_force_configuration?).and_return(force_indicator)
              end
              runner(platform: platform, version: version, step_into: ['nvidia_imex'])
            end
            cached(:node) { chef_run.node }

            before do
              chef_run.node.override['cluster']['region'] = 'aws_region'
              chef_run.node.override['cluster']['nvidia']['imex']['force_configuration'] = force_indicator
              chef_run.node.override['cluster']['node_type'] = node_type

              ConvergeNvidiaImex.configure(chef_run)
            end

            if %w(HeadNode LoginNode).include?(node_type)
              it 'does not configure nvidia-imex' do
                is_expected.not_to create_if_missing_template("#{imex_nodes_conf_file}")
                  .with(source: 'nvidia-imex/nvidia-imex-nodes.erb')
                  .with(user: 'root')
                  .with(group: 'root')
                  .with(mode: '0755')
                is_expected.not_to start_service('nvidia-imex').with_action(%i(enable start)).with_supports({ status: true })
              end
            else
              it 'it starts nvidia-imex service' do
                is_expected.to create_if_missing_template("#{imex_nodes_conf_file}")
                  .with(source: 'nvidia-imex/nvidia-imex-nodes.erb')
                  .with(user: 'root')
                  .with(group: 'root')
                  .with(mode: '0755')
                is_expected.to start_service('nvidia-imex').with_action(%i(enable start)).with_supports({ status: true })
              end
            end
          end
        end

        context "when is_gb200_node? is false" do
          cached(:chef_run) do
            stubs_for_provider('nvidia_imex[configure]') do |pro|
              allow(pro).to receive(:imex_installed?).and_return(true)
              allow(pro).to receive(:is_gb200_node?).and_return(false)
              allow(pro).to receive(:enable_force_configuration?).and_return(force_indicator)
            end
            runner = runner(platform: platform, version: version, step_into: ['nvidia_imex'])
            ConvergeNvidiaImex.configure(runner)
          end
          cached(:node) { chef_run.node }

          before do
            chef_run.node.override['cluster']['region'] = 'aws_region'
            chef_run.node.override['cluster']['nvidia']['imex']['force_configuration'] = force_indicator
          end

          if ['true', 'yes', true].include?(force_indicator)
            it 'does configure nvidia-imex' do
              is_expected.to start_service('nvidia-imex').with_action(%i(enable start)).with_supports({ status: true })
            end
          else
            it 'does not configure nvidia-imex' do
              is_expected.not_to start_service('nvidia-imex').with_action(%i(enable start)).with_supports({ status: true })
            end
          end
        end
      end
    end
  end
end
