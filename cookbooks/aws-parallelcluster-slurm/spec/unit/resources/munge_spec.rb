require 'spec_helper'

class ConvergeMunge
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-slurm') do
      munge 'setup' do
        action :setup
      end
    end
  end

  def self.purge_packages(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-slurm') do
      munge 'purge_packages' do
        action :purge_packages
      end
    end
  end

  def self.download_source_code(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-slurm') do
      munge 'download_source_code' do
        action :download_source_code
      end
    end
  end

  def self.compile_and_install(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-slurm') do
      munge 'compile_and_install' do
        action :compile_and_install
      end
    end
  end

  def self.set_user_and_group(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-slurm') do
      munge 'set_user_and_group' do
        action :set_user_and_group
      end
    end
  end

  def self.create_required_directories(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-slurm') do
      munge 'create_required_directories' do
        action :create_required_directories
      end
    end
  end
end

describe 'munge:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:munge_version) { '0.5.16' }
      cached(:munge_libdir) do
        case platform
        when 'ubuntu'
          '/usr/lib'
        else
          '/usr/lib64'
        end
      end
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:redhat_on_docker?).and_return(false)
        stub_command("/usr/sbin/munged --version | grep -q munge-#{munge_version} && ls #{munge_libdir}/libmunge*").and_return(false)
        runner = runner(platform: platform, version: version, step_into: ['munge'])
        ConvergeMunge.setup(runner)
      end

      it 'sets up munge' do
        is_expected.to setup_munge('setup')
      end

      it 'creates sources directory' do
        is_expected.to create_directory('/opt/parallelcluster/sources').with(recursive: true)
      end

      it 'updates package repos' do
        is_expected.to update_package_repos('update package repos')
      end

      it 'installs build tools' do
        is_expected.to setup_build_tools('Prerequisite: build tools')
      end

      it 'installs prerequisite packages' do
        expected_packages = case platform
                            when 'ubuntu'
                              %w(automake autoconf libtool libssl-dev)
                            when 'amazon'
                              if version == '2'
                                %w(automake autoconf libtool openssl11-devel)
                              else
                                %w(automake autoconf libtool openssl-devel)
                              end
                            else
                              %w(automake autoconf libtool openssl-devel)
                            end
        is_expected.to install_install_packages('prerequisites').with(packages: expected_packages)
      end
    end
  end
end

describe 'munge:purge_packages' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['munge'])
        ConvergeMunge.purge_packages(runner)
      end

      it 'purges munge packages' do
        is_expected.to purge_package(%w(munge* libmunge*))
      end
    end
  end
end

describe 'munge:download_source_code' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['munge'])
        ConvergeMunge.download_source_code(runner)
      end

      it 'downloads munge source code' do
        is_expected.to create_if_missing_remote_file('/opt/parallelcluster/sources/munge-0.5.16.tar.gz')
          .with(mode: '0644')
          .with(retries: 3)
          .with(retry_delay: 5)
      end
    end
  end
end

describe 'munge:compile_and_install' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:munge_libdir) do
        case platform
        when 'ubuntu'
          '/usr/lib'
        else
          '/usr/lib64'
        end
      end
      cached(:chef_run) do
        stub_command("/usr/sbin/munged --version | grep -q munge-0.5.16 && ls #{munge_libdir}/libmunge*").and_return(false)
        runner = runner(platform: platform, version: version, step_into: ['munge'])
        ConvergeMunge.compile_and_install(runner)
      end

      it 'compiles and installs munge' do
        is_expected.to run_bash('make install')
          .with(user: 'root')
          .with(group: 'root')
          .with(cwd: Chef::Config[:file_cache_path])
      end
    end
  end
end

describe 'munge:set_user_and_group' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['munge'])
        ConvergeMunge.set_user_and_group(runner)
      end

      it 'creates munge group' do
        is_expected.to create_group('munge')
          .with(comment: 'munge group')
          .with(gid: 402)
          .with(system: true)
      end

      it 'creates munge user' do
        is_expected.to create_user('munge')
          .with(uid: 402)
          .with(gid: 402)
          .with(manage_home: false)
          .with(comment: 'munge user')
          .with(system: true)
          .with(shell: '/sbin/nologin')
      end
    end
  end
end

describe 'munge:create_required_directories' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['munge'])
        ConvergeMunge.create_required_directories(runner)
      end

      it 'creates required munge directories' do
        %w(/var/log/munge /etc/munge /var/run/munge).each do |dir|
          is_expected.to create_directory(dir)
            .with(owner: 'munge')
            .with(group: 'munge')
        end
      end
    end
  end
end
