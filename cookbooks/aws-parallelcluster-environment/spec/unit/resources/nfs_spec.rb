require 'spec_helper'

class ConvergeNfs
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      nfs 'setup' do
        action :setup
      end
    end
  end

  def self.configure(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      nfs 'configure' do
        action :configure
      end
    end
  end
end

describe 'nfs:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:disabled_service) { 'disable_service' }
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['nfs']) do |node|
          node.override['nfs']['service']['server'] = disabled_service
        end
        ConvergeNfs.setup(runner)
      end

      it 'sets up nfs' do
        is_expected.to setup_nfs('setup')
      end

      if %w(amazon centos redhat).include?(platform)
        it 'installs nfs::server4' do
          expect(chef_run).to include_recipe('nfs::server4')
          chef_run
        end

      elsif platform == 'ubuntu'
        it 'installs nfs::server and nfs:server4' do
          expect(chef_run).to include_recipe('nfs::server')
          expect(chef_run).to include_recipe('nfs::server4')
          chef_run
        end

      else
        pending "to be implemented"
      end

      it 'disables service at boot' do
        is_expected.to disable_service(disabled_service)
      end
    end
  end
end

describe 'nfs:configure' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version} on node type HeadNode" do
      cached(:threads) { 10 }
      cached(:server_template) { 'server_template' }
      cached(:nfs_service) { 'nfs_service' }
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['nfs']) do |node|
          node.override['cluster']['nfs']['threads'] = threads
          node.override['nfs']['config']['server_template'] = server_template
          node.override['nfs']['service']['server'] = nfs_service
          node.override['cluster']['node_type'] = "HeadNode"
        end
        ConvergeNfs.configure(runner)
      end

      it 'configures nfs' do
        is_expected.to configure_nfs('configure')
      end

      if %w(amazon centos).include?(platform)
        it 'overrides nfs config with custom template' do
          is_expected.to create_template(server_template)
            .with(source: 'nfs/default-nfs-kernel-server.conf.erb')
            .with(cookbook: 'aws-parallelcluster-environment')
        end

      elsif %w(ubuntu).include?(platform)
        it 'overrides nfs config with custom template' do
          if version.to_i >= 22
            is_expected.to create_template(server_template)
              .with(source: 'nfs/nfs-ubuntu22+.conf.erb')
              .with(cookbook: 'aws-parallelcluster-environment')
          else
            is_expected.to create_template(server_template)
              .with(source: 'nfs/default-nfs-kernel-server.conf.erb')
              .with(cookbook: 'aws-parallelcluster-environment')
          end
        end

      elsif %(redhat rocky).include?(platform)
        it 'uses nfs config template shipped with nfs cookbook' do
          is_expected.to create_template(server_template)
            .with(source: "#{server_template}.erb")
            .with(cookbook: 'nfs')
        end

      else
        pending "to be implemented"
      end

      it 'enables and restarts service' do
        is_expected.to restart_service(nfs_service)
          .with(action: %i(restart enable))
          .with(supports: { restart: true })
      end
    end

    context "on #{platform}#{version} on node type ComputeFleet" do
      cached(:server_template) { 'server_template' }
      cached(:nfs_service) { 'nfs_service' }
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['nfs']) do |node|
          node.override['cluster']['node_type'] = "ComputeFleet"
        end
        ConvergeNfs.configure(runner)
      end

      it 'configures nfs' do
        is_expected.to configure_nfs('configure')
      end

      it 'not overrides nfs config with custom template' do
        is_expected.to_not create_template(server_template)
      end

      it 'not enables and restarts service' do
        is_expected.to_not restart_service(nfs_service)
      end
    end
  end
end
