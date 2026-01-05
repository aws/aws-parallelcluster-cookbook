require 'spec_helper'

describe 'aws-parallelcluster-computefleet::config_check_update_systemd_service' do
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

      it 'enables and starts the pcluster-check-update.timer service' do
        is_expected.to enable_service('pcluster-check-update.timer')
        is_expected.to start_service('pcluster-check-update.timer')
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

        it 'sets filesystem timeout to 20 seconds for file operations' do
          is_expected.to render_file('/etc/systemd/system/pcluster-check-update.service')
            .with_content('FS_TIMEOUT=20')
        end

        it 'applies filesystem timeout to reading shared file' do
          is_expected.to render_file('/etc/systemd/system/pcluster-check-update.service')
            .with_content('CURRENT_UPDATE=$(timeout $FS_TIMEOUT cat "$SHARED_FILE"')
        end

        it 'applies filesystem timeout to reading checkpoint file' do
          is_expected.to render_file('/etc/systemd/system/pcluster-check-update.service')
            .with_content('LAST_APPLIED=$(timeout $FS_TIMEOUT cat "$LOCAL_CHECKPOINT"')
        end

        it 'applies filesystem timeout to writing checkpoint file' do
          is_expected.to render_file('/etc/systemd/system/pcluster-check-update.service')
            .with_content('timeout $FS_TIMEOUT sh -c "echo \\"$CURRENT_UPDATE\\" > \\"$LOCAL_CHECKPOINT\\""')
        end

        it 'exits with error if checkpoint write fails' do
          is_expected.to render_file('/etc/systemd/system/pcluster-check-update.service')
            .with_content('$LOCAL_CHECKPOINT"" || exit 1')
        end

        it 'references the correct shared update path' do
          is_expected.to render_file('/etc/systemd/system/pcluster-check-update.service')
            .with_content("SHARED_FILE=\"#{node['cluster']['update']['trigger_file']}\"")
        end

        it 'references the correct local checkpoint path' do
          is_expected.to render_file('/etc/systemd/system/pcluster-check-update.service')
            .with_content("LOCAL_CHECKPOINT=\"#{node['cluster']['update']['checkpoint_file']}\"")
        end

        it 'calls cfn-hup-update-action.sh for the update' do
          is_expected.to render_file('/etc/systemd/system/pcluster-check-update.service')
            .with_content("#{node['cluster']['scripts_dir']}/cfn-hup-update-action.sh")
        end
      end
    end
  end
end
