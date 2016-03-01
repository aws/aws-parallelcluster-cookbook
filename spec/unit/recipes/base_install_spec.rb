require_relative '../spec_helper'

describe 'cfncluster::base_install' do
	let(:url)   { 'http://www.example.com/blob.tar.gz' }

  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'centos', version: '6.6') do |node|
      node.set['cfncluster']['udev_url'] = url
    end.converge(described_recipe)
  end

  before do
    stub_command("which getenforce").and_return(true)
  end

  # TODO: Need matchers for selinux 

  it 'requires proper recipes to build a single box stack' do
    expect(chef_run).to include_recipe('build-essential')
    expect(chef_run).to include_recipe('python')
    expect(chef_run).to include_recipe('awscli')
    expect(chef_run).to include_recipe('nfs')
    expect(chef_run).to include_recipe('nfs::server')
  end

  it 'testing cookbook_file' do
    expect(chef_run).to create_cookbook_file('/usr/local/sbin/configure-pat.sh')
  end

	it 'testing remote file' do
		expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/ec2-udev.tar.gz")
			.with_source(url)
			.with_mode('0644')
	end

	code = <<-EOF
    tar xf ec2-udev.tar.gz
    cd ec2-udev-scripts-*
    make install
  EOF

  it 'properly installs ec2-udev-scripts' do
		expect(chef_run).to run_bash('make install')
      .with_user('root')
      .with_group('root')
      .with_cwd(Chef::Config[:file_cache_path])
      .with_code(code)
      .with_creates('/usr/local/sbin/attachVolume.py')
  end

  it 'test python package installs using pip' do
    expect(chef_run).to install_python_pip('cfncluster-node')
    expect(chef_run).to install_python_pip('supervisor')
  end

  it 'test extra packages are installed' do
    chef_run.node['cfncluster']['base_packages'].each do |p|
      expect(chef_run).to install_package(p)
    end
  end

end