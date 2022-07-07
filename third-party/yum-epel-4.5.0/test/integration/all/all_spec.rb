os_release = os.name == 'amazon' ? 7 : os.release.to_i
stream = file('/etc/os-release').content.match?('Stream')
infra =
  if os.name == 'oracle'
    '$infra'
  elsif os.name == 'almalinux'
    'stock'
  elsif stream
    'stock'
  else
    'container'
  end

content = case os.name
          when 'oracle' then '$contentdir'
          when 'rocky'  then 'pub/rocky'
          when 'almalinux' then 'almalinux'
          else 'centos'
          end

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
else
  %w(
    epel-modular
    epel-modular-debuginfo
    epel-modular-source
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
