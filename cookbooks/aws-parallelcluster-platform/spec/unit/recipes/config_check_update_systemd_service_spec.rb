require 'spec_helper'

describe 'aws-parallelcluster-platform::config_check_update_systemd_service' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          node.override['cluster']['node_type'] = 'ComputeFleet'
        end
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'creates the pcluster-check-update.service template' do
        is_expected.to create_template('/etc/systemd/system/pcluster-check-update.service')
          .with(source: 'check_update/pcluster-check-update.service.erb')
          .with(owner: 'root')
          .with(group: 'root')
          .with(mode: '0644')
      end

      it 'creates the pcluster-check-update.timer file' do
        is_expected.to create_cookbook_file('/etc/systemd/system/pcluster-check-update.timer')
          .with(source: 'check_update/pcluster-check-update.timer')
          .with(owner: 'root')
          .with(group: 'root')
          .with(mode: '0644')
      end

      it 'creates the shared update path file if missing' do
        is_expected.to create_file_if_missing(node['cluster']['update']['trigger_file'])
          .with(content: '')
          .with(owner: 'root')
          .with(group: 'root')
          .with(mode: '0644')
      end

      it 'creates the local update checkpoint file if missing' do
        is_expected.to create_file_if_missing(node['cluster']['update']['checkpoint_file'])
          .with(content: '')
          .with(owner: 'root')
          .with(group: 'root')
          .with(mode: '0644')
      end

      describe 'pcluster-check-update.service template content' do
        it 'has Type=oneshot to prevent concurrent executions' do
          is_expected.to render_file('/etc/systemd/system/pcluster-check-update.service')
            .with_content('Type=oneshot')
        end

        it 'has TimeoutStartSec set to compute_node_bootstrap_timeout' do
          is_expected.to render_file('/etc/systemd/system/pcluster-check-update.service')
            .with_content("TimeoutStartSec=#{node['cluster']['compute_node_bootstrap_timeout']}")
        end

        it 'calls pcluster-check-update.sh script' do
          is_expected.to render_file('/etc/systemd/system/pcluster-check-update.service')
            .with_content("ExecStart=#{node['cluster']['scripts_dir']}/pcluster-check-update.sh")
        end

        it 'logs output to pcluster-check-update.log' do
          is_expected.to render_file('/etc/systemd/system/pcluster-check-update.service')
            .with_content("StandardOutput=append:#{node['cluster']['log_base_dir']}/pcluster-check-update.log")
        end
      end
    end
  end
end
