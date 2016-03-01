require_relative '../spec_helper'

describe 'cfncluster::sge_install' do
	let(:url)   { 'http://www.example.com/blob.tar.gz' }

  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'centos', version: '6.6') do |node|
      node.set['cfncluster']['sge_url'] = url
    end.converge(described_recipe)
  end

  before do
    stub_command("which getenforce").and_return(true)
  end

	it 'testing remote file' do
		expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/sge.tar.gz")
			.with_source(url)
			.with_mode('0644')
	end

	code = <<-EOF
    tar xf sge.tar.gz
    cd sge*/source
    sh scripts/bootstrap.sh -no-java -no-jni -no-herd
    ./aimk -pam -no-remote -no-java -no-jni -no-herd
    ./aimk -man -no-java -no-jni -no-herd
    scripts/distinst -local -allall -noexit
    mkdir $SGE_ROOT
    echo instremote=false >> distinst.private
    gearch=`dist/util/arch`
    echo 'y'| scripts/distinst -local -allall ${gearch}
  EOF

  it 'properly installs SGE' do
		expect(chef_run).to run_bash('make install')
      .with_user('root')
      .with_group('root')
      .with_cwd(Chef::Config[:file_cache_path])
      .with_code(code)
      .with_creates('/opt/sge/bin/lx-amd64/sge_qmaster')
  end

end