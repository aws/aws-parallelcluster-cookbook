require 'spec_helper'

describe 'aws-parallelcluster-slurm::config_slurm_accounting' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do
          allow_any_instance_of(Object).to receive(:are_mount_or_unmount_required?).and_return(false)
          allow_any_instance_of(Object).to receive(:dig).and_return(true)
          RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
        end
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'creates the service definition for slurmdbd' do
        is_expected.to create_template('/etc/systemd/system/slurmdbd.service').with(
          source: 'slurm/head_node/slurmdbd.service.erb',
          owner: 'root',
          group: 'root',
          mode:  '0644'
        )
      end

      it 'creates the service definition for slurmdbd with the correct settings' do
        is_expected.to render_file('/etc/systemd/system/slurmdbd.service')
          .with_content("After=network-online.target munge.service mysql.service mysqld.service mariadb.service remote-fs.target")
      end

      it 'creates the slurmdbd configuration files' do
        slurm_install_dir = "#{node['cluster']['slurm']['install_dir']}"
        slurm_user  = "#{node['cluster']['slurm']['user']}"
        slurm_group = "#{node['cluster']['slurm']['group']}"
        is_expected.to create_template("/etc/systemd/system/slurmdbd.service").with(
          source: 'slurm/head_node/slurmdbd.service.erb',
          user: 'root',
          group: 'root',
          mode:  '0644'
        )
        is_expected.to create_template_if_missing("#{slurm_install_dir}/etc/slurmdbd.conf").with(
          source: 'slurm/slurmdbd.conf.erb',
          user: slurm_user,
          group: slurm_group,
          mode:  '0600'
        )
        is_expected.to create_file("#{slurm_install_dir}/etc/slurm_parallelcluster_slurmdbd.conf").with(
          user: slurm_user,
          group: slurm_group,
          mode:  '0600'
        )
      end

      it 'creates the Slurm database password update script' do
        is_expected.to create_template("#{node['cluster']['scripts_dir']}/slurm/update_slurm_database_password.sh").with(
          source: 'slurm/head_node/update_slurm_database_password.sh.erb',
          user: 'root',
          group: 'root',
          mode:  '0700'
        )
      end

      it 'executes the Slurm database password update scripts' do
        is_expected.to run_execute("update Slurm database password").with(
          command: "#{node['cluster']['scripts_dir']}/slurm/update_slurm_database_password.sh",
          user: "root",
          group: "root"
        )
      end

      it 'starts the slurm database daemon' do
        is_expected.to enable_service("slurmdbd")
        is_expected.to start_service("slurmdbd")
      end

      it "waits for the Slurm database to respond" do
        is_expected.to run_execute("wait for slurm database").with(
          command: "#{node['cluster']['slurm']['install_dir']}/bin/sacctmgr show clusters -Pn"
        )
      end

      it "bootstraps the Slurm database idempotently" do
        is_expected.to run_bash("bootstrap slurm database")
      end
    end
  end
end
