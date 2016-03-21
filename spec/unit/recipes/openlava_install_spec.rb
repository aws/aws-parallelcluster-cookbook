require_relative '../spec_helper'

describe 'cfncluster::openlava_install' do
  let(:url)   { 'http://www.example.com/blob.tar.gz' }

  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'centos', version: '6.6') do |node|
      node.set['cfncluster']['openlava_url'] = url
    end.converge(described_recipe)
  end

  before do
    stub_command("which getenforce").and_return(true)
  end

  it 'testing remote file' do
    expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/openlava.tar.gz")
      .with_source(url)
      .with_mode('0644')
  end

  code = <<-EOF
    tar xf openlava.tar.gz
    cd openlava*
    ./bootstrap.sh
    ./configure --prefix=/opt/openlava-2.2
    make install
  EOF

  it 'properly installs Openlava' do
    expect(chef_run).to run_bash('make install')
      .with_user('root')
      .with_group('root')
      .with_cwd(Chef::Config[:file_cache_path])
      .with_code(code)
      .with_creates('/opt/openlava-2.2/bin/lsid')
  end
end
