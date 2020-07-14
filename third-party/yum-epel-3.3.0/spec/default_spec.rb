require 'spec_helper'

describe 'yum-epel::default' do
  context 'yum-epel::default uses default attributes' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '7.3.1611') do |node|
        node.override['yum']['epel']['managed'] = true
        node.override['yum']['epel-debuginfo']['managed'] = true
        node.override['yum']['epel-source']['managed'] = true
        node.override['yum']['epel-testing']['managed'] = true
        node.override['yum']['epel-testing-debuginfo']['managed'] = true
        node.override['yum']['epel-testing-source']['managed'] = true
      end.converge(described_recipe)
    end

    %w(
      epel
      epel-debuginfo
      epel-source
      epel-testing
      epel-testing-debuginfo
      epel-testing-source
    ).each do |repo|
      it "creates yum_repository[#{repo}]" do
        expect(chef_run).to create_yum_repository(repo)
      end
    end
  end

  # do these specs seem like overkill to you?
  # well we want to make sure someone REALLY doesn't try to set the URL back to $releasever
  # That equals release7 on RHEL 7 and EPEL repo doesn't return anything for that so please
  # leave node['platform_version'].to_i

  context 'on RHEL 6' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.9').converge('yum-epel::default')
    end

    it 'creates epel repo with proper version string' do
      expect(chef_run).to create_yum_repository('epel').with(mirrorlist: 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch')
    end
  end

  context 'on RHEL 7' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '7.3.1611').converge('yum-epel::default')
    end

    it 'creates epel repo with proper version string' do
      expect(chef_run).to create_yum_repository('epel').with(mirrorlist: 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-7&arch=$basearch')
    end
  end

  context 'on Amazon 2018' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'amazon', version: '2018.03').converge('yum-epel::default')
    end

    it 'creates epel repo with proper version string' do
      expect(chef_run).to create_yum_repository('epel').with(mirrorlist: 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch')
    end
  end

  context 'on Amazon 2' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'amazon', version: '2').converge('yum-epel::default')
    end

    it 'creates epel repo with proper version string' do
      expect(chef_run).to create_yum_repository('epel').with(mirrorlist: 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-7&arch=$basearch')
    end
  end
end
