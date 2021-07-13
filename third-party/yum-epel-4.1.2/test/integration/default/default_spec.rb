os_release = os.name == 'amazon' ? '7' : os.release.to_i

describe yum.repo 'epel' do
  it { should exist }
  it { should be_enabled }
  its('mirrors') { should cmp "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-#{os_release}&arch=x86_64" }
end

%w(
  epel-debuginfo
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
