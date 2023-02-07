control 'sticky_bits_configured' do
  title 'Check sticky bits configuration'

  if os_properties.ubuntu2004? && !os_properties.virtualized?
    # This test passes on Mac but doesn't work as GitHub action.
    describe kernel_parameter('fs.protected_regular') do
      its('value') { should eq 0 }
    end
  end
end
