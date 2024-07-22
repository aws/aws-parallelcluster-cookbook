require 'spec_helper'

describe 'aws-parallelcluster-platform::supervisord_config' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version).converge(described_recipe)
      end

      it 'creates the supervisord template with the correct attributes' do
        is_expected.to create_template('/etc/parallelcluster/parallelcluster_supervisord.conf').with(
          source: 'supervisord/parallelcluster_supervisord.conf.erb',
          owner: 'root',
          group: 'root',
          mode:  '0644'
        )
      end

      context "when head node and dcv configured" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'HeadNode'
            node.override['cluster']['dcv_enabled'] = 'head_node'
            allow_any_instance_of(Object).to receive(:dcv_installed?).and_return(true)
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'has the correct content' do
          is_expected.to render_file('/etc/parallelcluster/parallelcluster_supervisord.conf')
            .with_content("[program:cfn-hup]")
            .with_content("[program:clustermgtd]")
            .with_content("[program:clusterstatusmgtd]")
            .with_content("[program:pcluster_dcv_authenticator]")
            .with_content("--port 8444")
        end

        context "when head node and dcv not configured" do
          cached(:chef_run) do
            runner = runner(platform: platform, version: version) do |node|
              node.override['cluster']['node_type'] = 'HeadNode'
              node.override['cluster']['dcv_enabled'] = 'NONE'
              allow_any_instance_of(Object).to receive(:dcv_installed?).and_return(true)
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
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'ComputeFleet'
            node.override['cluster']['dcv_enabled'] = 'head_node'
            allow_any_instance_of(Object).to receive(:dcv_installed?).and_return(false)
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'has the correct content' do
          is_expected.to render_file('/etc/parallelcluster/parallelcluster_supervisord.conf')
            .with_content("[program:cfn-hup]")
            .with_content("[program:computemgtd]")

          is_expected.not_to render_file('/etc/parallelcluster/parallelcluster_supervisord.conf')
            .with_content("[program:pcluster_dcv_authenticator]")
        end
      end
      context "when login node and dcv configured" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'LoginNode'
            node.override['cluster']['dcv_enabled'] = 'login_node'
            allow_any_instance_of(Object).to receive(:dcv_installed?).and_return(true)
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'has the correct content' do
          is_expected.to render_file('/etc/parallelcluster/parallelcluster_supervisord.conf')
            .with_content("[program:cfn-hup]")
            .with_content("[program:loginmgtd]")
            .with_content("[program:pcluster_dcv_authenticator]")
            .with_content("--port 8444")
        end

        context "when login node and dcv not configured" do
          cached(:chef_run) do
            runner = runner(platform: platform, version: version) do |node|
              node.override['cluster']['node_type'] = 'LoginNode'
              node.override['cluster']['dcv_enabled'] = 'NONE'
              allow_any_instance_of(Object).to receive(:dcv_installed?).and_return(true)
            end
            runner.converge(described_recipe)
          end
          cached(:node) { chef_run.node }

          it 'has the correct content' do
            is_expected.to render_file('/etc/parallelcluster/parallelcluster_supervisord.conf')
                             .with_content("[program:loginmgtd]")

            is_expected.not_to render_file('/etc/parallelcluster/parallelcluster_supervisord.conf')
                                 .with_content("[program:pcluster_dcv_authenticator]")
            end
          end
        end
      end
    end
end
