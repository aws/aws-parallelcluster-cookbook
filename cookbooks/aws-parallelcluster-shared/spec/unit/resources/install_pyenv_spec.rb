require 'spec_helper'

class ConvergeInstallPyenv
  def self.run(chef_run, python_version: nil, pyenv_root: nil, user_only: nil, user: nil)
    chef_run.converge_dsl('aws-parallelcluster-shared') do
      install_pyenv_new 'run' do
        action :run
        python_version python_version if python_version
        prefix pyenv_root if pyenv_root
        user_only true if user_only
        user user if user
      end
    end
  end
end

describe 'install_pyenv:run' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
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
      end

      context "when python version and pyenv root are set" do
        cached(:python_version) { 'python_version_parameter' }
        cached(:system_pyenv_root) { 'pyenv_root_parameter' }
        cached(:chef_run) do
          runner = ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['install_pyenv_new']
          ) do |node|
            node.override['cluster']['system_pyenv_root'] = 'default_system_pyenv_root'
            node.override['cluster']['python-version'] = 'default_python_version'
          end
          ConvergeInstallPyenv.run(runner, python_version: python_version, pyenv_root: system_pyenv_root)
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
      end

      context "when it is a user only installation" do
        context "and user is not set" do
          cached(:chef_run) do
            ChefSpec::Runner.new(
              platform: platform, version: version,
              step_into: ['install_pyenv_new']
            )
          end

          it 'raises exception' do
            expect { ConvergeInstallPyenv.run(chef_run, user_only: true) }.to raise_error(RuntimeError, /user property is required for resource install_pyenv when user_only is set to true/)
          end
        end

        context "and user is set" do
          cached(:user) { "the_user" }
          cached(:pyenv_root) { "pyenv_root" }
          cached(:python_version) { 'python_version' }
          cached(:chef_run) do
            runner = ChefSpec::Runner.new(
              platform: platform, version: version,
              step_into: ['install_pyenv_new']
            )
            ConvergeInstallPyenv.run(runner, user_only: true, user: user, python_version: python_version, pyenv_root: pyenv_root)
          end

          it 'installs pyenv for user' do
            is_expected.to install_pyenv_user_install(python_version).with(
              user: user,
              user_prefix: pyenv_root
            )
          end
        end
      end
    end
  end
end
