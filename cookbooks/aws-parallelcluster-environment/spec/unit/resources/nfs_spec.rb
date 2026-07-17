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
      cached(:server_service) { 'nfs_server_service' }
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['nfs']) do |node|
          node.override['nfs']['service']['server'] = server_service
        end
        ConvergeNfs.setup(runner)
      end

      it 'sets up nfs' do
        is_expected.to setup_nfs('setup')
      end

      it 'installs the full NFS stack (client + server) via nfs::server4' do
        expect(chef_run).to include_recipe('nfs::server4')
        chef_run
      end

      if %w(ubuntu debian).include?(platform)
        it 'also includes nfs::server on Debian (sous-chefs/nfs#93 workaround)' do
          expect(chef_run).to include_recipe('nfs::server')
          chef_run
        end
      end

      it 'does not start the nfs server at boot' do
        is_expected.to disable_service(server_service)
      end
    end
  end
end

describe 'nfs:configure' do
  for_all_oses do |platform, version|
    cached(:server_service) { 'nfs_server_service' }
    cached(:nfs_conf) { '/etc/nfs.conf' }
    cached(:nfs_conf_dropin) { '/etc/nfs.conf.d/parallelcluster-nfs.conf' }

    context "on #{platform}#{version} on node type HeadNode" do
      cached(:threads) { 10 }
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['nfs']) do |node|
          node.override['nfs']['service']['server'] = server_service
          node.override['cluster']['nfs']['threads'] = threads
          node.override['cluster']['node_type'] = "HeadNode"
        end
        ConvergeNfs.configure(runner)
      end

      it 'configures nfs' do
        is_expected.to configure_nfs('configure')
      end

      if %w(amazon redhat rocky centos).include?(platform) && version.to_i == 8
        it 'renders /etc/nfs.conf with the NFSv4-only template (no conf.d on el8)' do
          is_expected.to create_template(nfs_conf)
            .with(source: 'nfs/nfs.conf.erb')
            .with(cookbook: 'aws-parallelcluster-environment')
          is_expected.to_not create_template(nfs_conf_dropin)
        end

        it 'disables NFSv3 and enables NFSv4 in /etc/nfs.conf' do
          expect(chef_run).to render_file(nfs_conf).with_content(/vers3=no/)
          expect(chef_run).to render_file(nfs_conf).with_content(/vers4=yes/)
        end

        it 'restart of the server is notified when /etc/nfs.conf changes' do
          expect(chef_run.template(nfs_conf)).to notify("service[#{server_service}]").to(:restart).delayed
        end
      else
        it 'ships an NFSv4-only drop-in and leaves /etc/nfs.conf untouched' do
          is_expected.to create_template(nfs_conf_dropin)
            .with(source: 'nfs/parallelcluster-nfs.conf.erb')
            .with(cookbook: 'aws-parallelcluster-environment')
          is_expected.to_not create_template(nfs_conf)
        end

        it 'disables NFSv3 and enables NFSv4 in the drop-in' do
          expect(chef_run).to render_file(nfs_conf_dropin).with_content(/vers3=no/)
          expect(chef_run).to render_file(nfs_conf_dropin).with_content(/vers4=yes/)
        end

        it 'pins the ancillary v3 client ports in the drop-in (unpinned by nfs::server4 on AL2023)' do
          expect(chef_run).to render_file(nfs_conf_dropin).with_content(/\[statd\]\nport=32765\noutgoing-port=32766/)
          expect(chef_run).to render_file(nfs_conf_dropin).with_content(/\[mountd\]\nport=32767/)
          expect(chef_run).to render_file(nfs_conf_dropin).with_content(/\[lockd\]\nport=4045\nudp-port=4045/)
        end

        it 'restart of the server is notified when the drop-in changes' do
          expect(chef_run.template(nfs_conf_dropin)).to notify("service[#{server_service}]").to(:restart).delayed
        end
      end

      it 'enables and starts the server' do
        is_expected.to enable_service(server_service)
        is_expected.to start_service(server_service)
      end

      context 'when v3 is re-enabled via node attribute' do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['nfs']) do |node|
            node.override['nfs']['service']['server'] = server_service
            node.override['cluster']['nfs']['threads'] = threads
            node.override['nfs']['v3'] = 'yes'
            node.override['cluster']['node_type'] = 'HeadNode'
          end
          ConvergeNfs.configure(runner)
        end

        it 'advertises vers3 in the rendered config' do
          target = (%w(redhat rocky centos).include?(platform) && version.to_i == 8) ? nfs_conf : nfs_conf_dropin
          expect(chef_run).to render_file(target).with_content(/vers3=yes/)
        end
      end
    end

    context "on #{platform}#{version} on node type ComputeFleet" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['nfs']) do |node|
          node.override['nfs']['service']['server'] = server_service
          node.override['cluster']['node_type'] = "ComputeFleet"
        end
        ConvergeNfs.configure(runner)
      end

      it 'configures nfs' do
        is_expected.to configure_nfs('configure')
      end

      it 'does not manage the NFS server config (client-only node)' do
        is_expected.to_not create_template(nfs_conf)
        is_expected.to_not create_template(nfs_conf_dropin)
      end

      it 'stops and disables the server (client-only node)' do
        is_expected.to stop_service(server_service)
        is_expected.to disable_service(server_service)
      end
    end
  end
end
