# Use the name matching the resource type
control 'efs_utils_installed' do
  title 'Verify that efs_utils is installed'

  only_if { !os_properties.redhat_ubi? }

  describe package('amazon-efs-utils') do
    it { should be_installed }
  end

  if os_properties.alinux2?
    describe package('stunnel5') do
      it { should be_installed }
    end
  end
end
