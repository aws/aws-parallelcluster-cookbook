# Use the name matching the resource type
control 'tag:install_install_packages' do
  title 'Test installation of packages'

  only_if { !os_properties.redhat_ubi? }

  # verify package with a common name is installed
  describe package('coreutils') do
    it { should be_installed }
  end

  # verify dns-domain package
  describe package('hostname') do
    it { should be_installed }
  end

  if os.redhat? # redhat includes amazon

    describe package('glibc-static') do
      it { should be_installed }
    end

    describe package('kernel-devel') do
      it { should be_installed }
    end unless os_properties.on_docker?

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
    end unless os_properties.on_docker?

  else
    describe "unsupported OS" do
      # this produces a skipped control (ignore-like)
      # adding a new OS to kitchen platform list and running the tests,
      # it would surface the fact this recipe does not support this OS.
      pending "support for #{os.name}-#{os.release} needs to be implemented"
    end
  end
end
