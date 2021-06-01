os_release = os.name == 'amazon' ? 7 : os.release.to_i
infra = os.name == 'oracle' ? '$infra' : 'container'
content = os.name == 'oracle' ? '$contentdir' : 'centos'

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
  describe yum.repo 'epel-modular' do
    it { should exist }
    it { should be_enabled }
    its('mirrors') { should cmp "https://mirrors.fedoraproject.org/metalink?repo=epel-modular-8&arch=x86_64&infra=#{infra}&content=#{content}" }
  end

  describe yum.repo 'epel-modular-debuginfo' do
    it { should exist }
    it { should be_enabled }
    its('mirrors') { should cmp "https://mirrors.fedoraproject.org/metalink?repo=epel-modular-debug-8&arch=x86_64&infra=#{infra}&content=#{content}" }
  end

  describe yum.repo 'epel-modular-source' do
    it { should exist }
    it { should be_enabled }
    its('mirrors') { should cmp "https://mirrors.fedoraproject.org/metalink?repo=epel-modular-source-8&arch=x86_64&infra=#{infra}&content=#{content}" }
  end

  describe yum.repo 'epel-playground' do
    it { should exist }
    it { should be_enabled }
    its('mirrors') { should cmp "https://mirrors.fedoraproject.org/metalink?repo=playground-epel8&arch=x86_64&infra=#{infra}&content=#{content}" }
  end

  describe yum.repo 'epel-playground-debuginfo' do
    it { should exist }
    it { should be_enabled }
    its('mirrors') { should cmp "https://mirrors.fedoraproject.org/metalink?repo=playground-debug-epel8&arch=x86_64&infra=#{infra}&content=#{content}" }
  end

  describe yum.repo 'epel-playground-source' do
    it { should exist }
    it { should be_enabled }
    its('mirrors') { should cmp "https://mirrors.fedoraproject.org/metalink?repo=playground-source-epel8&arch=x86_64&infra=#{infra}&content=#{content}" }
  end

  describe yum.repo 'epel-testing-modular' do
    it { should exist }
    it { should be_enabled }
    its('mirrors') { should cmp "https://mirrors.fedoraproject.org/metalink?repo=testing-modular-epel8&arch=x86_64&infra=#{infra}&content=#{content}" }
  end

  describe yum.repo 'epel-testing-modular-debuginfo' do
    it { should exist }
    it { should be_enabled }
    its('mirrors') { should cmp "https://mirrors.fedoraproject.org/metalink?repo=testing-modular-debug-epel8&arch=x86_64&infra=#{infra}&content=#{content}" }
  end

  describe yum.repo 'epel-testing-modular-source' do
    it { should exist }
    it { should be_enabled }
    its('mirrors') { should cmp "https://mirrors.fedoraproject.org/metalink?repo=testing-modular-source-epel8&arch=x86_64&infra=#{infra}&content=#{content}" }
  end
else
  %w(
    epel-modular
    epel-modular-debuginfo
    epel-modular-source
    epel-playground
    epel-playground-debuginfo
    epel-playground-source
    epel-testing-modular
    epel-testing-modular-debuginfo
    epel-testing-modular-source
  ).each do |repo|
    describe yum.repo repo do
      it { should_not exist }
      it { should_not be_enabled }
    end
  end
end
