require 'spec_helper'

describe 'aws-parallelcluster-common::node_attributes' do
  context 'Sets up environment variables' do
    cached(:chef_run) do
      runner = ChefSpec::Runner.new(step_into: ['node_attributes']) do |node|
        node.override['test']['attr'] = 'attr_value'
      end
      runner.converge_dsl do
        node_attributes 'write file'
      end
    end

    it 'creates file /etc/chef/node_attributes.json with all the node attributes' do
      is_expected.to render_file('/etc/chef/node_attributes.json')
        .with_content(/"test": {\s*"attr": "attr_value"\s*}/)
    end
  end
end
