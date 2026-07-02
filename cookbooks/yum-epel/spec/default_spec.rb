require 'spec_helper'

describe 'yum-epel::default' do
  context 'yum-epel::default uses default attributes' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '7') do |node|
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

  context 'on CentOS 7' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '7').converge('yum-epel::default')
    end

    it do
      expect(chef_run).to create_yum_repository('epel').with(mirrorlist: 'https://mirrors.fedoraproject.org/mirrorlist?repo=epel-7&arch=$basearch')
    end
  end

  context 'on CentOS 8' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '8').converge('yum-epel::default')
    end

    it do
      expect(chef_run).to create_yum_repository('epel').with(mirrorlist: 'https://mirrors.fedoraproject.org/mirrorlist?repo=epel-8&arch=$basearch')
    end
  end

  context 'on CentOS Stream 8' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '8') do |node|
        node.automatic['os_release']['name'] = 'CentOS Stream'
      end.converge('yum-epel::default')
    end

    it do
      expect(chef_run).to create_yum_repository('epel-next').with(mirrorlist: 'https://mirrors.fedoraproject.org/mirrorlist?repo=epel-next-8&arch=$basearch')
    end

    it do
      expect(chef_run).to create_yum_repository('epel')
    end
  end

  context 'on Alma Linux 8' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'almalinux', version: '8').converge('yum-epel::default')
    end

    it do
      expect(chef_run).to create_yum_repository('epel').with(mirrorlist: 'https://mirrors.fedoraproject.org/mirrorlist?repo=epel-8&arch=$basearch')
    end
  end

  context 'on Rocky Linux 8' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'rocky', version: '8').converge('yum-epel::default')
    end

    it do
      expect(chef_run).to create_yum_repository('epel').with(mirrorlist: 'https://mirrors.fedoraproject.org/mirrorlist?repo=epel-8&arch=$basearch')
    end
  end

  context 'on Amazon 2' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'amazon', version: '2').converge('yum-epel::default')
    end

    it do
      expect(chef_run).to create_yum_repository('epel').with(mirrorlist: 'https://mirrors.fedoraproject.org/mirrorlist?repo=epel-7&arch=$basearch')
    end
  end

  context 'on debian' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'debian', version: '10').converge('yum-epel::default')
    end
    it do
      expect(chef_run).to_not create_yum_repository('epel')
    end
  end
end
