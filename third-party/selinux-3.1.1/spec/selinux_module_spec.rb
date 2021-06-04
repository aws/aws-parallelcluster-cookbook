require 'spec_helper'

describe 'selinux_module_test::create' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'centos', step_into: ['selinux_module'])
                        .converge(described_recipe)
  end

  let(:selinux_file) { '/etc/selinux/local/test.te' }
  let(:selinux_contents) do
    File.open(
      File.expand_path(
        './test/fixtures/cookbooks/selinux_module_test/files/selinux/test.te')
    ).read
  end
  let(:sefile) { SELinux::File.new(selinux_contents) }

  let(:module_name) { 'aiccu' }
  let(:module_version) { '1.1.0' }
  let(:semodule) { SELinux::Module.new(module_name) }

  before do
    runner = double('shellout_double')
    expect(Mixlib::ShellOut).to(receive(:new).and_return(runner))
    expect(runner).to(receive(:run_command))
    expect(runner).to(receive(:stderr).and_return(''))
    expect(runner).to(receive(:stdout).and_return(<<-EOS)
abrt       1.4.1
accountsd  1.1.0
acct       1.6.0
afs        1.9.0
aiccu      1.1.0
aide       1.7.1
ajaxterm   1.0.0
alsa       1.12.2
    EOS
                     )
  end

  before :each do
    allow(File).to(
      receive(:exist?).and_call_original)
    allow(File).to(
      receive(:exist?).with(/test.pp/).and_return(true))
  end

  it 'installs the dependency packages' do
    expect(chef_run).to(install_package('make, policycoreutils, selinux-policy-devel'))
  end

  it 'logs the steps taken' do
    expect(chef_run).to(write_log(/selinux/))
    expect(chef_run).to(write_log(/Target checksum/))
  end

  it 'installs `test` selinux module' do
    expect(chef_run).to(
      ChefSpec::Matchers::ResourceMatcher.new(
        :selinux_module, :create, 'create'))
    expect(chef_run).to(
      run_execute(/Compiling SELinux/).with_command(/^make -C/))
    expect(chef_run).not_to(
      run_ruby_block('look_for_pp_file'))
    expect(chef_run).to(
      run_execute(/^semodule --install/))
    expect(chef_run).to(
      create_directory(File.dirname(selinux_file)))
    expect(chef_run).to(
      render_file(selinux_file).with_content(selinux_contents))
  end
end

describe 'selinux_module_test::remove' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'centos', step_into: ['selinux_module'])
                        .converge(described_recipe)
  end

  before do
    runner = double('shellout_double')
    expect(Mixlib::ShellOut).to(receive(:new).and_return(runner))
    expect(runner).to(receive(:run_command))
    expect(runner).to(receive(:stderr).and_return(''))
    expect(runner).to(receive(:stdout).and_return(''))
  end

  it 'removes the `test` selinux module' do
    expect(chef_run).to(
      ChefSpec::Matchers::ResourceMatcher.new(
        :selinux_module, :remove, 'test'))
  end
end

# EOF
