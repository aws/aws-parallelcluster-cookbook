os_release = os.name == 'amazon' ? 9 : os.release.to_i
stream = file('/etc/os-release').content.match?('Stream')

describe yum.repo 'epel' do
  it { should exist }
  it { should be_enabled }
  its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-#{os_release}&arch=x86_64" }
end

describe yum.repo 'epel-debuginfo' do
  it { should exist }
  it { should be_enabled }
  its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-debug-#{os_release}&arch=x86_64" }
end

describe yum.repo 'epel-source' do
  it { should exist }
  it { should be_enabled }
  its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-source-#{os_release}&arch=x86_64" }
end

describe yum.repo 'epel-testing' do
  it { should exist }
  it { should be_enabled }
  its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=testing-epel#{os_release}&arch=x86_64" }
end

describe yum.repo 'epel-testing-debuginfo' do
  it { should exist }
  it { should be_enabled }
  its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=testing-debug-epel#{os_release}&arch=x86_64" }
end

describe yum.repo 'epel-testing-source' do
  it { should exist }
  it { should be_enabled }
  its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=testing-source-epel#{os_release}&arch=x86_64" }
end

if os_release >= 8
  if stream
    describe yum.repo 'epel-next' do
      it { should exist }
      it { should be_enabled }
      its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-next-#{os_release}&arch=x86_64" }
    end

    describe yum.repo 'epel-next-debuginfo' do
      it { should exist }
      it { should be_enabled }
      its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-next-debug-#{os_release}&arch=x86_64" }
    end

    describe yum.repo 'epel-next-source' do
      it { should exist }
      it { should be_enabled }
      its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-next-source-#{os_release}&arch=x86_64" }
    end

    describe yum.repo 'epel-next-testing' do
      it { should exist }
      it { should be_enabled }
      its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-testing-next-#{os_release}&arch=x86_64" }
    end

    describe yum.repo 'epel-next-testing-debuginfo' do
      it { should exist }
      it { should be_enabled }
      its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-testing-next-debug-#{os_release}&arch=x86_64" }
    end

    describe yum.repo 'epel-next-testing-source' do
      it { should exist }
      it { should be_enabled }
      its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=testing-source-epel#{os_release}&arch=x86_64" }
    end
  end
end
