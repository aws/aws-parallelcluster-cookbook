require 'spec_helper'

class ConvergeNfs
  def self.setup(chef_run)
    chef_run.converge_dsl('nfs::server', 'nfs::server4', 'nfs::_common') do
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
      let(:chef_run) do
        ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['nfs']
        )
      end

      let(:node) { chef_run.node }
      let(:nfs_service) { platform == 'ubuntu' ? 'nfs-kernel-server.service' : 'nfs-server.service' }

      before :each do
        block_stepping_into_recipe
      end

      if %w(amazon centos redhat).include?(platform)
        # It doesn't work because nfs::server fails to use `template` resource
        # It should skip the entire recipe but it doesn't work.
        #
        # TODO: find a way to fix
        #
        # it 'installs nfs::server4' do
        #   expect_to_include_recipe_from_resource('nfs::server')
        #   expect_to_include_recipe_from_resource('nfs::server4')
        #   ConvergeNfs.setup(chef_run)
        # end
        #
        # it 'disables service at boot' do
        #   ConvergeNfs.setup(chef_run)
        #   is_expected.to disable_service(nfs_service)
        # end

      elsif %w(ubuntu).include?(platform)
        it 'installs nfs::server and disables service start at boot' do
          expect_to_include_recipe_from_resource('nfs::server')
          expect_to_include_recipe_from_resource('nfs::server4')
          ConvergeNfs.setup(chef_run)
          expect(chef_run).to disable_service(nfs_service)
        end

      else
        pending "Implement for #{platform}"
      end
    end
  end
end
