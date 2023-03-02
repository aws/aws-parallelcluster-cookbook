control 'lustre_client_installed' do
  title "Verify that lustre client is installed"

  if (os_properties.centos? && inspec.os.release.to_f >= 7.5) || os_properties.redhat?
    describe package('kmod-lustre-client') do
      it { should be_installed }
    end

    describe package('lustre-client') do
      it { should be_installed }
    end

    if (os_properties.centos? && inspec.os.release.to_f >= 7.7) || os_properties.redhat?
      describe yum.repo('aws-fsx') do
        it { should exist }
        it { should be_enabled }
        its('baseurl') { should include 'fsx-lustre-client-repo.s3.amazonaws.com' }
      end
    end
  end

  if os_properties.debian_family?
    describe apt('https://fsx-lustre-client-repo.s3.amazonaws.com/ubuntu') do
      it { should exist }
      it { should be_enabled }
    end

    describe package('lustre-client-modules-aws') do
      it { should be_installed }
    end

    kernel_release = os_properties.ubuntu2004? ? '5.15.0-1028-aws' : '5.4.0-1092-aws'
    describe package("lustre-client-modules-#{kernel_release}") do
      it { should be_installed }
    end
  end

  if os_properties.alinux2?
    describe package('lustre-client') do
      it { should be_installed }
    end

    describe yum.repo('amzn2extra-lustre2.10') do
      it { should exist }
      it { should be_enabled }
    end
  end
end

control 'lnet_kernel_module_enabled' do
  title "Verify that lnet kernel module is enabled"
  only_if { !os_properties.virtualized? && !os_properties.alinux2? }
  describe kernel_module("lnet") do
    it { should be_loaded }
    it { should_not be_disabled }
    it { should_not be_blacklisted }
  end
end
