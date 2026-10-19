# frozen_string_literal: true

require 'spec_helper'

describe 'aws-parallelcluster-platform::enable_chef_error_handler' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      for_all_node_types do |node_type|
        context "when #{node_type}" do
          cached(:chef_run) do
            runner(platform: platform, version: version) do |node|
              node.override['cluster']['node_type'] = node_type
              node.override['cluster']['scheduler'] = 'slurm'
            end.converge(described_recipe)
          end

          it 'enables the service failure handler' do
            expect(chef_run).to enable_chef_handler('ErrorHandlers::ServiceFailureHandler').with(type: { exception: true })
          end
        end
      end
    end
  end
end
