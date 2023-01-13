# Use the name matching the resource type
control 'example_resource' do
  # describe the resource
  title 'Example resource'

  describe file('/tmp/example_file') do
    it { should exist }
  end
end
