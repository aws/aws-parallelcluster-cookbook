require 'spec_helper'

describe 'aws-parallelcluster-config::sudo' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        ChefSpec::Runner.new(platform: platform, version: version).converge(described_recipe)
      end

      it 'creates the sudoers template with the correct attributes' do
        is_expected.to create_template('/etc/sudoers.d/99-parallelcluster-user-tty').with(
          owner: 'root',
          group: 'root',
          mode:  '0600'
        )
      end

      it 'creates the supervisord template with the correct attributes' do
        is_expected.to create_template('/etc/parallelcluster/parallelcluster_supervisord.conf').with(
          owner: 'root',
          group: 'root',
          mode:  '0644'
        )
      end

      context "when head node and dcv configured" do
        cached(:chef_run) do
          runner = ChefSpec::Runner.new(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'HeadNode'
            node.override['cluster']['dcv_enabled'] = 'head_node'
            node.override['conditions']['dcv_supported'] = true
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'has the correct content' do
          is_expected.to render_file('/etc/parallelcluster/parallelcluster_supervisord.conf')
            .with_content("[program:clusterstatusmgtd]")
            .with_content("[program:pcluster_dcv_authenticator]")
            .with_content("--port 8444")
        end

        context "when head node and dcv not configured" do
          cached(:chef_run) do
            runner = ChefSpec::Runner.new(platform: platform, version: version) do |node|
              node.override['cluster']['node_type'] = 'HeadNode'
              node.override['cluster']['dcv_enabled'] = 'NONE'
              node.override['conditions']['dcv_supported'] = true
            end
            runner.converge(described_recipe)
          end
          cached(:node) { chef_run.node }

          it 'has the correct content' do
            is_expected.to render_file('/etc/parallelcluster/parallelcluster_supervisord.conf')
              .with_content("[program:clusterstatusmgtd]")

            is_expected.not_to render_file('/etc/parallelcluster/parallelcluster_supervisord.conf')
              .with_content("[program:pcluster_dcv_authenticator]")
          end
        end
      end

      context "when compute fleet" do
        cached(:chef_run) do
          runner = ChefSpec::Runner.new(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'ComputeFleet'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'has the correct content' do
          is_expected.to render_file('/etc/parallelcluster/parallelcluster_supervisord.conf')
            .with_content("[program:computemgtd]")
        end
      end
    end
  end
end
