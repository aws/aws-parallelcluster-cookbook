require 'spec_helper'

class ConvergeOsType
  def self.validate(chef_run, base_os: nil)
    chef_run.converge_dsl('aws-parallelcluster-shared') do
      os_type 'validate' do
        action :validate
        base_os base_os
      end
    end
  end
end

describe 'os_type:validate' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:correct_base_os) do
        case platform
        when 'ubuntu'
          "#{platform}#{version.tr('.', '')}"
        when 'amazon'
          "alinux#{version}"
        when 'centos'
          "centos#{version.to_i}"
        when 'redhat'
          "rhel#{version.to_i}"
        when 'rocky'
          "rocky#{version.to_i}"
        else
          raise "Unsupported OS #{platform}"
        end
      end
      cached(:wrong_base_os) { 'wrong_base_os' }

      context 'when wrong OS passed' do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['os_type'])
          ConvergeOsType.validate(runner, base_os: wrong_base_os)
        end

        it 'fails in case of wrong OS' do
          expect { chef_run }.to(raise_error do |error|
            expect(error).to be_a(RuntimeError)
            expect(error.message).to match /The custom AMI you have provided uses the #{correct_base_os} OS./
            expect(error.message).to match /However, the base_os specified in your config file is #{wrong_base_os}./
            expect(error.message).to match /Please either use an AMI with the #{wrong_base_os} OS or update the base_os setting in your configuration file to #{correct_base_os}./
          end)
        end
      end

      context 'when correct OS passed' do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['os_type'])
          ConvergeOsType.validate(runner, base_os: correct_base_os)
        end

        it 'succeeds' do
          expect { chef_run }.not_to raise_error
        end
      end

      context 'when no OS passed' do
        cached(:os_from_node_attribute) { 'os from node attribute' }
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['os_type']) do |node|
            node.override['cluster']['base_os'] = os_from_node_attribute
          end
          ConvergeOsType.validate(runner)
        end

        it "defaults to node['cluster']['base_os']" do
          expect { chef_run }.to raise_error(RuntimeError)
            .with_message(/the base_os specified in your config file is #{os_from_node_attribute}/)
        end
      end
    end
  end
end
