# Use the name matching the resource type
control 'tag:install_install_packages' do
  title 'Test installation of packages'

  only_if { !os_properties.redhat_on_docker? }

  # verify package with a common name is installed
  describe package('moreutils') do
    it { should be_installed }
  end unless os_properties.alinux2023?

  # verify dns-domain package
  describe package('hostname') do
    it { should be_installed }
  end

  # Verify jq version is updated enough to accept 2 argfile parameters
  describe bash("jq --argfile") do
    its('stderr') { should match /jq: --argfile takes two parameters/ }
  end unless instance.custom_ami? || os_properties.alinux2023?
  # Need to change the jq --argfile commands as its deprecated in 1.7( latest)

  unless os_properties.centos7?
    # Verify fftw package is not installed
    describe bash('ls 2>/dev/null /usr/lib64/libfftw*') do
      its('stdout') { should be_empty }
    end
    describe bash('ls 2>/dev/null /usr/lib/libfftw*') do
      its('stdout') { should be_empty }
    end
  end

  # Verify mpich package is not installed
  describe bash('ls 2>/dev/null /usr/lib64/mpich*') do
    its('stdout') { should be_empty }
  end
  describe bash('ls 2>/dev/null /usr/lib/mpich*') do
    its('stdout') { should be_empty }
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
