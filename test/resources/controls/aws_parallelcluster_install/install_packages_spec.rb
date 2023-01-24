# Use the name matching the resource type
control 'install_packages' do
  title 'Test installation of packages'

  only_if { !os_properties.redhat_ubi? }

  describe package('lvm2') do
    it { should be_installed }
  end

  if os.redhat? # redhat includes amazon

    describe package('glibc-static') do
      it { should be_installed }
    end

    describe package('kernel-devel') do
      it { should be_installed }
    end unless os_properties.docker?

    # Check amazon linux2 extra
    if os_properties.alinux2?
      describe package('R-core') do
        it { should be_installed }
      end
    end

  elsif os.debian?

    describe package('libssl-dev') do
      it { should be_installed }
    end

    describe bash('dpkg -l | grep linux-headers') do
      its('exit_status') { should eq 0 }
    end unless os_properties.docker?

  else
    describe "unsupported OS" do
      # this produces a skipped control (ignore-like)
      # adding a new OS to kitchen platform list and running the tests,
      # it would surface the fact this recipe does not support this OS.
      pending "support for #{os.name}-#{os.release} needs to be implemented"
    end
  end
end
