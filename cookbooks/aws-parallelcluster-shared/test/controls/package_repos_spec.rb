# Use the name matching the resource type
control 'tag:install_package_repos' do
  # describe the resource
  title 'Configure package manager repository'

  only_if { !os_properties.alinux2023? }
  # in this case, different OSes produce different outcomes, to be tested differently
  if os.redhat? # redhat includes amazon

    describe bash('yum repolist') do
      its('exit_status') { should eq 0 }
      its('stdout')      { should match %r{epel[/ ]} }
    end

    if os[:name] == 'redhat' && virtualization.system != 'docker'
      describe yum.repo("codeready-builder-for-rhel-#{os[:release].to_i}-rhui-rpms") do
        it { should exist }
        it { should be_enabled }
      end
    end

    if os[:name] == 'centos'
      describe bash('yum-config-manager --enable | grep skip_if_unavailable | grep -v True') do
        its('exit_status') { should eq 1 }
      end
    end

  elsif os.debian?

    # apt_update touches this file: if it exists it means apt_update has been performed
    describe file('/var/lib/apt/periodic/update-success-stamp') do
      it { should exist }
    end

  else
    describe "unsupported OS" do
      # this produces a skipped control (ignore-like)
      # adding a new OS to kitchen platform list and running the tests,
      # it would surface the fact this recipe does not support this OS.
      pending "support for #{os.name}-#{os.release} needs to be implemented"
    end
  end
end
