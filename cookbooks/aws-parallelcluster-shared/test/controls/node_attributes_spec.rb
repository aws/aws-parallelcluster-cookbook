control 'tag:install_node_attributes_created' do
  title 'Test the generation of the node attributes json file'

  describe file('/etc/chef/node_attributes.json') do
    it { should exist }
    its('content') { should match(/^    "cluster": \{$/) }
    # its('content_as_json') { should include('cluster') }
    # its('content_as_json') { should include('cluster' => { 'base_dir' => '/opt/parallelcluster' }) }
  end
end
