require 'spec_helper'

class ConvergeNvidiaDcgm
  def self.setup(chef_run, nvidia_enabled: nil)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      nvidia_dcgm 'setup' do
        nvidia_enabled nvidia_enabled
        action :setup
      end
    end
  end
end

describe 'nvidia_dcgm:_nvidia_enabled' do
  context 'when nvidia enabled property is set' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(step_into: ['nvidia_dcgm']) do |node|
        node.override['cluster']['nvidia']['enabled'] = false
      end
    end
    cached(:resource) do
      ConvergeNvidiaDcgm.setup(chef_run, nvidia_enabled: true)
      chef_run.find_resource('nvidia_dcgm', 'setup')
    end

    it "takes precedence over node['cluster']['nvidia']['enabled'] attribute" do
      expect(resource._nvidia_enabled).to eq(true)
    end
  end

  context 'when nvidia enabled property is not set' do
    context "and node['cluster']['nvidia']['enabled'] is true" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(step_into: ['nvidia_dcgm']) do |node|
          node.override['cluster']['nvidia']['enabled'] = true
        end
      end
      cached(:resource) do
        ConvergeNvidiaDcgm.setup(chef_run)
        chef_run.find_resource('nvidia_dcgm', 'setup')
      end
      it "is true" do
        expect(resource._nvidia_enabled).to eq(true)
      end
    end

    context "and node['cluster']['nvidia']['enabled'] is yes" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(step_into: ['nvidia_dcgm']) do |node|
          node.override['cluster']['nvidia']['enabled'] = 'yes'
        end
      end
      cached(:resource) do
        ConvergeNvidiaDcgm.setup(chef_run)
        chef_run.find_resource('nvidia_dcgm', 'setup')
      end
      it "is true" do
        expect(resource._nvidia_enabled).to eq(true)
      end
    end

    context "and node['cluster']['nvidia']['enabled'] is not yes or true" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(step_into: ['nvidia_dcgm']) do |node|
          node.override['cluster']['nvidia']['enabled'] = 'any'
        end
      end
      cached(:resource) do
        ConvergeNvidiaDcgm.setup(chef_run)
        chef_run.find_resource('nvidia_dcgm', 'setup')
      end
      it "is false" do
        expect(resource._nvidia_enabled).to eq(false)
      end
    end
  end
end

describe 'nvidia_dcgm:_nvidia_dcgm_enabled' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'when on arm and nvidia enabled' do
        cached(:chef_run) do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
          runner(platform: platform, version: version, step_into: ['nvidia_dcgm'])
        end
        cached(:resource) do
          ConvergeNvidiaDcgm.setup(chef_run, nvidia_enabled: true)
          chef_run.find_resource('nvidia_dcgm', 'setup')
        end

        if %w(centos amazon).include?(platform)
          it "is not enabled" do
            expect(resource._nvidia_dcgm_enabled).to eq(false)
          end
        else
          it "is enabled" do
            expect(resource._nvidia_dcgm_enabled).to eq(true)
          end
        end
      end

      context 'when not on arm' do
        cached(:chef_run) do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          runner(platform: platform, version: version, step_into: ['nvidia_dcgm'])
        end

        context 'when nvidia enabled' do
          cached(:resource) do
            ConvergeNvidiaDcgm.setup(chef_run, nvidia_enabled: true)
            chef_run.find_resource('nvidia_dcgm', 'setup')
          end

          it "is enabled" do
            expect(resource._nvidia_dcgm_enabled).to eq(true)
          end
        end

        context 'when nvidia not enabled' do
          cached(:resource) do
            ConvergeNvidiaDcgm.setup(chef_run, nvidia_enabled: false)
            chef_run.find_resource('nvidia_dcgm', 'setup')
          end

          it "is not enabled" do
            expect(resource._nvidia_dcgm_enabled).to eq(false)
          end
        end
      end
    end
  end
end

describe 'nvidia_dcgm:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'when nvidia not enabled' do
        cached(:chef_run) do
          stubs_for_resource('nvidia_dcgm') do |res|
            allow(res).to receive(:_nvidia_enabled).and_return(false)
          end
          runner = runner(platform: platform, version: version, step_into: ['nvidia_dcgm'])
          ConvergeNvidiaDcgm.setup(runner)
        end
        cached(:node) { chef_run.node }

        it 'does not install datacenter gpu manager' do
          is_expected.not_to run_bash('Install datacenter-gpu-manager')
        end
      end

      context 'when nvidia enabled' do
        cached(:chef_run) do
          stubs_for_resource('nvidia_dcgm') do |res|
            allow(res).to receive(:_nvidia_enabled).and_return(true)
          end
          runner(platform: platform, version: version, step_into: ['nvidia_dcgm'])
        end

        context 'and it is an arm instance' do
          before do
            allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
            ConvergeNvidiaDcgm.setup(chef_run)
          end

          if %w(centos amazon).include?(platform)
            it 'does not install datacenter gpu manager' do
              is_expected.not_to run_bash('Install datacenter-gpu-manager')
            end
          else
            it 'installs datacenter gpu manager' do
              is_expected.to run_bash('Install datacenter-gpu-manager')
            end
          end
        end

        context 'and it is not an arm instance' do
          before do
            allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
            ConvergeNvidiaDcgm.setup(chef_run)
          end

          it 'sets up nvidia_dcgm' do
            is_expected.to setup_nvidia_dcgm('setup')
          end

          # it 'installs datacenter gpu manager' do
          #   is_expected.to install_package('datacenter-gpu-manager')
          # end
        end
      end
    end
  end
end
