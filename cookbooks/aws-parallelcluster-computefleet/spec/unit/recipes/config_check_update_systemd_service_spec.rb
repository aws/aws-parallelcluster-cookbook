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

      it 'creates the check-update.service template' do
        is_expected.to create_template('/etc/systemd/system/check-update.service')
          .with(source: 'check_update/check-update.service.erb')
          .with(owner: 'root')
          .with(group: 'root')
          .with(mode: '0644')
      end

      it 'creates the check-update.timer file' do
        is_expected.to create_cookbook_file('/etc/systemd/system/check-update.timer')
          .with(source: 'check_update/check-update.timer')
          .with(owner: 'root')
          .with(group: 'root')
          .with(mode: '0644')
      end

      it 'creates the shared update path file if missing' do
        is_expected.to create_file_if_missing(node['cluster']['shared_update_path'])
          .with(content: '')
          .with(owner: 'root')
          .with(group: 'root')
          .with(mode: '0644')
      end

      it 'creates the local update checkpoint file if missing' do
        is_expected.to create_file_if_missing(node['cluster']['update_checkpoint'])
          .with(content: '')
          .with(owner: 'root')
          .with(group: 'root')
          .with(mode: '0644')
      end

      it 'enables and starts the check-update.timer service' do
        is_expected.to enable_service('check-update.timer')
        is_expected.to start_service('check-update.timer')
      end

      describe 'check-update.service template content' do
        it 'has Type=oneshot to prevent concurrent executions' do
          is_expected.to render_file('/etc/systemd/system/check-update.service')
            .with_content('Type=oneshot')
        end

        it 'has TimeoutStartSec=30 to handle NFS hangs' do
          is_expected.to render_file('/etc/systemd/system/check-update.service')
            .with_content('TimeoutStartSec=30')
        end

        it 'exits gracefully if shared file does not exist' do
          is_expected.to render_file('/etc/systemd/system/check-update.service')
            .with_content('[ ! -f "$SHARED_FILE" ] && exit 0')
        end

        it 'exits gracefully if cat fails' do
          is_expected.to render_file('/etc/systemd/system/check-update.service')
            .with_content('CURRENT_UPDATE=$(cat "$SHARED_FILE") || exit 0')
        end

        it 'writes checkpoint before running update action' do
          is_expected.to render_file('/etc/systemd/system/check-update.service')
            .with_content('echo "$CURRENT_UPDATE" > "$LOCAL_CHECKPOINT" && ')
        end

        it 'references the correct shared update path' do
          is_expected.to render_file('/etc/systemd/system/check-update.service')
            .with_content("SHARED_FILE=\"#{node['cluster']['shared_update_path']}\"")
        end

        it 'references the correct local checkpoint path' do
          is_expected.to render_file('/etc/systemd/system/check-update.service')
            .with_content("LOCAL_CHECKPOINT=\"#{node['cluster']['update_checkpoint']}\"")
        end

        it 'calls cfn-hup-update-action.sh when update is needed' do
          is_expected.to render_file('/etc/systemd/system/check-update.service')
            .with_content("#{node['cluster']['scripts_dir']}/cfn-hup-update-action.sh")
        end
      end
    end
  end
end
