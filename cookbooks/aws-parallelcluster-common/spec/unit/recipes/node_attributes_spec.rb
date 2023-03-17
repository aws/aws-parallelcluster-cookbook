require 'spec_helper'

describe 'aws-parallelcluster-common::node_attributes' do
  context 'Sets up environment variables' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'ubuntu') do |node|
        node.override['test']['attr'] = 'attr_value'
      end.converge(described_recipe)
    end

    it 'creates file /etc/chef/node_attributes.json with all the node attributes' do
      is_expected.to render_file('/etc/chef/node_attributes.json')
        .with_content(/"test": {\s*"attr": "attr_value"\s*}/)
    end
  end
end
