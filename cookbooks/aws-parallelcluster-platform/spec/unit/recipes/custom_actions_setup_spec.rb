require 'spec_helper'

describe 'aws-parallelcluster-platform::custom_actions_setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:instance_id) { 'i-xxx' }
      cached(:instance_type) { 't2.xlarge' }
      cached(:availability_zone) { 'eu-west-1a' }
      cached(:hostname) { 'hostname' }
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          node.override['ec2']['instance_id'] = "#{instance_id}"
          node.override['ec2']['instance_type'] = "#{instance_type}"
          node.override['ec2']['availability_zone'] = "#{availability_zone}"
          node.override['ec2']['hostname'] = "#{hostname}"
        end
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'installs the ssh target checker with the correct attributes' do
        is_expected.to create_template("#{node['cluster']['scripts_dir']}/fetch_and_run").with(
          source: "custom_actions/fetch_and_run.erb",
          owner: 'root',
          group: 'root',
          mode:  '0755',
          variables: {
            scheduler: node['cluster']['scheduler'],
            cluster_name: node['cluster']['cluster_name'] || node['cluster']['stack_name'],
            instance_id: "#{instance_id}",
            instance_type: "#{instance_type}",
            availability_zone: "#{availability_zone}",
            ip_address: node['ipaddress'],
            hostname: "#{hostname}",
            compute_resource: node['cluster']['scheduler_compute_resource_name'],
            node_spec_file: "#{node['cluster']['slurm_plugin_dir']}/slurm_nodename",
          }
        )
      end

      it 'has the correct content' do
        is_expected.to render_file("#{node['cluster']['scripts_dir']}/fetch_and_run")
          .with_content("--instance-id \"#{instance_id}\"")
          .with_content("--node-spec-file \"/etc/parallelcluster/slurm_plugin/slurm_nodename\"")
      end

      it 'creates custom_action_executor.py' do
        is_expected.to create_if_missing_cookbook_file("#{node['cluster']['scripts_dir']}/custom_action_executor.py").with(
          source: "custom_action_executor/custom_action_executor.py",
          owner: "root",
          group: "root",
          mode: "0755"
        )
      end
    end
  end
end
