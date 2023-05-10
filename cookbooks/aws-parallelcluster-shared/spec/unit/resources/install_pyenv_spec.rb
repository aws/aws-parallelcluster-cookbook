require 'spec_helper'

class ConvergeInstallPyenv
  def self.run(chef_run, python_version = nil, system_pyenv_root = nil)
    chef_run.converge_dsl('aws-parallelcluster-shared') do
      install_pyenv_new 'run' do
        action :run
        python_version python_version if python_version
        prefix system_pyenv_root if system_pyenv_root
      end
    end
  end

  def self.run_user_only(chef_run, user, prefix)
    chef_run.converge_dsl('aws-parallelcluster-shared') do
      install_pyenv_new 'run' do
        action :run
        user_only true
        user user
        prefix prefix
      end
    end
  end
end

default_python_version = '3.9.16'
default_system_pyenv_root = '/opt/parallelcluster/pyenv'

describe 'install_pyenv:run' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context "when python version and pyenv root are not set and not overridden through node attributes" do
        cached(:chef_run) do
          runner = ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['install_pyenv_new']
          )
          ConvergeInstallPyenv.run(runner)
        end
        cached(:node) { chef_run.node }

        it 'installs pyenv' do
          # This is a redundant check
          # Without it ChefSpec coverage sees install_pyenv:run as not covered resource
          is_expected.to run_install_pyenv_new('run')
        end

        it 'creates system pyenv root dir' do
          is_expected.to create_directory(default_system_pyenv_root).with_recursive(true)
        end

        it 'installs pyenv system with default python version and system pyenv root' do
          is_expected.to install_pyenv_system_install(default_python_version)
            .with_global_prefix(default_system_pyenv_root)
        end

        it 'removes /etc/profile.d/pyenv.sh' do
          is_expected.to delete_file('/etc/profile.d/pyenv.sh')
        end

        it 'installs default python version' do
          is_expected.to install_pyenv_python(default_python_version)
        end

        it 'installs pyenv plugin virtualenv' do
          is_expected.to install_pyenv_plugin('virtualenv')
            .with_git_url('https://github.com/pyenv/pyenv-virtualenv')
        end

        it 'sets node attributes python-version and system_pyenv_root' do
          expect(node.default['cluster']['system_pyenv_root']).to eq(default_system_pyenv_root)
          expect(node.default['cluster']['python-version']).to eq(default_python_version)
          is_expected.to write_node_attributes('dump node attributes')
        end
      end

      context "when python version and pyenv root are not set but are overridden through node attributes" do
        cached(:python_version) { 'overridden_python_version' }
        cached(:system_pyenv_root) { 'overridden_pyenv_root' }
        cached(:chef_run) do
          runner = ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['install_pyenv_new']
          ) do |node|
            node.override['cluster']['system_pyenv_root'] = system_pyenv_root
            node.override['cluster']['python-version'] = python_version
          end
          ConvergeInstallPyenv.run(runner)
        end
        cached(:node) { chef_run.node }

        it 'creates pyenv root dir' do
          is_expected.to create_directory(system_pyenv_root).with_recursive(true)
        end

        it 'installs pyenv system' do
          is_expected.to install_pyenv_system_install(python_version)
            .with_global_prefix(system_pyenv_root)
        end

        it 'installs default python version' do
          is_expected.to install_pyenv_python(python_version)
        end

        it 'sets node attributes python-version and system_pyenv_root' do
          expect(node.default['cluster']['system_pyenv_root']).to eq(system_pyenv_root)
          expect(node.default['cluster']['python-version']).to eq(python_version)
          is_expected.to write_node_attributes('dump node attributes')
        end
      end

      context "when python version and pyenv root are set" do
        cached(:python_version) { 'python_version_parameter' }
        cached(:system_pyenv_root) { 'pyenv_root_parameter' }
        cached(:chef_run) do
          runner = ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['install_pyenv_new']
          ) do |node|
            node.override['cluster']['system_pyenv_root'] = system_pyenv_root
            node.override['cluster']['python-version'] = python_version
          end
          ConvergeInstallPyenv.run(runner, python_version, system_pyenv_root)
        end
        cached(:node) { chef_run.node }

        it 'creates pyenv root dir' do
          is_expected.to create_directory(system_pyenv_root).with_recursive(true)
        end

        it 'installs pyenv system' do
          is_expected.to install_pyenv_system_install(python_version)
            .with_global_prefix(system_pyenv_root)
        end

        it 'installs default python version' do
          is_expected.to install_pyenv_python(python_version)
        end

        it 'sets node attributes python-version and system_pyenv_root' do
          expect(node.default['cluster']['system_pyenv_root']).to eq(system_pyenv_root)
          expect(node.default['cluster']['python-version']).to eq(python_version)
          is_expected.to write_node_attributes('dump node attributes')
        end
      end

      context "when it is a user only installation" do
        context "when user is not set" do
          cached(:chef_run) do
            ChefSpec::Runner.new(
              platform: platform, version: version,
              step_into: ['install_pyenv_new']
            )
          end

          it 'raises exception' do
            expect { ConvergeInstallPyenv.run_user_only(chef_run, nil, 'anything') }.to raise_error(RuntimeError, /user property is required for resource install_pyenv when user_only is set to true/)
          end
        end

        context "when user is set" do
          cached(:user) { "the_user" }
          cached(:user_prefix) { "the_user_prefix" }
          cached(:chef_run) do
            runner = ChefSpec::Runner.new(
              platform: platform, version: version,
              step_into: ['install_pyenv_new']
            )
            ConvergeInstallPyenv.run_user_only(runner, user, user_prefix)
          end

          it 'installs pyenv for user' do
            is_expected.to install_pyenv_user_install(default_python_version).with(
              user: user,
              user_prefix: user_prefix
            )
          end
        end
      end
    end
  end
end
