# Use the name matching the resource type
control 'example_recipe' do
  # describe the resource
  title 'Example recipe'

  describe file('/tmp/example_file') do
    it { should exist }
  end
end
