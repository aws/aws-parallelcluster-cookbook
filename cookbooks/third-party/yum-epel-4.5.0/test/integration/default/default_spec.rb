os_release = os.name == 'amazon' ? '7' : os.release.to_i
stream = file('/etc/os-release').content.match?('Stream')

describe yum.repo 'epel' do
  it { should exist }
  it { should be_enabled }
  its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-#{os_release}&arch=x86_64" }
end

describe yum.repo 'epel-next' do
  it { should exist }
  it { should be_enabled }
end if stream

%w(
  epel-debuginfo
  epel-next-debuginfo
  epel-next-source
  epel-next-testing
  epel-next-testing-debuginfo
  epel-next-testing-source
  epel-source
  epel-testing
  epel-testing-debuginfo
  epel-testing-source
).each do |repo|
  describe yum.repo repo do
    it { should_not exist }
    it { should_not be_enabled }
  end
end
