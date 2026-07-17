require 'spec_helper'

describe 'aws-parallelcluster-platform::config_check_update_systemd_service' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      %w(ComputeFleet LoginNode).each do |node_type|
        context "when #{node_type}" do
          cached(:chef_run) do
            runner = runner(platform: platform, version: version) do |node|
              node.override['cluster']['node_type'] = node_type
              node.override['cluster']['launch_template_id'] = 'LAUNCH_TEMPLATE_ID'
              node.override['cluster']['update']['dna_dir'] = 'DNA_DIR'
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

          it 'creates the cluster-update-action.sh template' do
            is_expected.to create_template("#{node['cluster']['scripts_dir']}/cluster-update-action.sh")
              .with(source: 'check_update/cluster-update-action.sh.erb')
              .with(owner: 'root')
              .with(group: 'root')
              .with(mode: '0700')
              .with(variables: {
                               monitor_shared_dir: node['cluster']['update']['dna_dir'],
                               launch_template_resource_id: node['cluster']['launch_template_id'],
                               exec_tmp_dir: node['cluster']['exec_tmp_dir'],
                             })
          end

          describe 'cluster-update-action.sh template content' do
            it 'monitors the dna_dir for the launch template dna.json' do
              is_expected.to render_file("#{node['cluster']['scripts_dir']}/cluster-update-action.sh")
                .with_content("LATEST_DNA_LOC=#{node['cluster']['update']['dna_dir']}")
            end

            it 'looks for the launch template specific dna.json file' do
              is_expected.to render_file("#{node['cluster']['scripts_dir']}/cluster-update-action.sh")
                .with_content("LATEST_DNA_FILE=$LATEST_DNA_LOC/#{node['cluster']['launch_template_id']}-dna.json")
            end
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
  end
end
