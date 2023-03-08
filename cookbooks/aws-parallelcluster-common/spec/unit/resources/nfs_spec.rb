require 'spec_helper'

class ConvergeNfs
  def self.setup(chef_run)
    chef_run.converge_dsl do
      nfs 'setup' do
        action :setup
      end
    end
  end

  def self.configure(chef_run)
    chef_run.converge_dsl do
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
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['nfs']
        ) do |node|
          node.override['nfs']['service']['server'] = disabled_service
        end
        ConvergeNfs.setup(runner)
      end

      if %w(amazon centos redhat).include?(platform)
        it 'installs nfs::server4' do
          expect_to_include_recipe_from_resource('nfs::server4')
          chef_run
        end

      elsif platform == 'ubuntu'
        it 'installs nfs::server and nfs:server4' do
          expect_to_include_recipe_from_resource('nfs::server')
          expect_to_include_recipe_from_resource('nfs::server4')
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
    context "on #{platform}#{version}" do
      cached(:threads) { 10 }
      cached(:server_template) { 'server_template' }
      cached(:nfs_service) { 'nfs_service' }
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['nfs']
        ) do |node|
          node.override['cluster']['nfs']['threads'] = threads
          node.override['nfs']['config']['server_template'] = server_template
          node.override['nfs']['service']['server'] = nfs_service
        end
        ConvergeNfs.configure(runner)
      end

      if %w(amazon centos ubuntu).include?(platform)
        it 'overrides nfs config with custom template' do
          is_expected.to create_template(server_template)
            .with(source: 'nfs/nfs.conf.erb')
            .with(cookbook: 'aws-parallelcluster-common')
        end

      elsif platform == 'redhat'
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
  end
end
