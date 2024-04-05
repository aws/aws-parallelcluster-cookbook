control 'tag:install_lustre_client_installed' do
  title "Verify that lustre client is installed"
  minimal_lustre_client_version = '2.12'
  if os_properties.centos? && inspec.os.release.to_f >= 7.5
    describe package('kmod-lustre-client') do
      it { should be_installed }
    end

    describe package('lustre-client') do
      it { should be_installed }
    end

    if os_properties.centos? && inspec.os.release.to_f >= 7.7
      describe package('kmod-lustre-client') do
        its('version') { should cmp >= minimal_lustre_client_version }
      end

      describe package('lustre-client') do
        its('version') { should cmp >= minimal_lustre_client_version }
      end

      describe yum.repo('aws-fsx') do
        it { should exist }
        it { should be_enabled }
        its('baseurl') { should include 'fsx-lustre-client-repo.s3.amazonaws.com' }
      end
    end
  end

  if os_properties.redhat? && inspec.os.release.to_f >= 8.2 && !os_properties.on_docker?
    # TODO: restore installation and check on docker when Lustre is available for RH8.9
    # See: https://docs.aws.amazon.com/fsx/latest/LustreGuide/install-lustre-client.html
    unless inspec.os.release.to_f == 8.7 && (node['cluster']['kernel_release'].include?("4.18.0-425.3.1.el8") || node['cluster']['kernel_release'].include?("4.18.0-425.13.1.el8_7"))
      describe package('kmod-lustre-client') do
        it { should be_installed }
      end

      describe package('lustre-client') do
        it { should be_installed }
      end

      describe package('kmod-lustre-client') do
        its('version') { should cmp >= minimal_lustre_client_version }
      end

      describe package('lustre-client') do
        its('version') { should cmp >= minimal_lustre_client_version }
      end

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
      its('version') { should cmp >= minimal_lustre_client_version }
    end

    describe package("lustre-client-modules-#{node['cluster']['kernel_release']}") do
      it { should be_installed }
      its('version') { should cmp >= minimal_lustre_client_version }
    end
  end

  if os_properties.alinux?
    describe package('lustre-client') do
      it { should be_installed }
      its('version') { should cmp >= minimal_lustre_client_version }
    end
  end  

  if os_properties.alinux2?
    describe yum.repo('amzn2extra-lustre') do
      it { should exist }
      it { should be_enabled }
    end
  end
end

control 'tag:install_lustre_lnet_kernel_module_enabled' do
  title "Verify that lnet kernel module is enabled"
  only_if { !os_properties.on_docker? && !os_properties.alinux? }
  describe kernel_module("lnet") do
    it { should be_loaded }
    it { should_not be_disabled }
    it { should_not be_blacklisted }
  end
end

control 'lustre_mounted' do
  only_if { !os_properties.on_docker? }
  describe mount('/shared_dir') do
    it { should be_mounted }
    its('type') { should eq 'lustre' }
  end
end

control 'lustre_unmounted' do
  only_if { !os_properties.on_docker? }

  describe mount('/shared_dir') do
    it { should_not be_mounted }
  end
end
