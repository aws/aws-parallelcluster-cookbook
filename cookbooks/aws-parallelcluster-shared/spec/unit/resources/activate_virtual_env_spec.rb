require 'spec_helper'

class ConvergeActivateVirtualEnv
  def self.run(chef_run, pyenv_name:, pyenv_path:, python_version:, user:, requirements: nil)
    chef_run.converge_dsl('aws-parallelcluster-shared') do
      activate_virtual_env 'run' do
        action :run
        pyenv_name pyenv_name
        pyenv_path pyenv_path
        python_version python_version
        requirements_path requirements
        user user
      end
    end
  end
end

describe 'activate_virtual_env:run' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:pyenv_name) { 'pyenv_name' }
      cached(:pyenv_path) { 'pyenv_path' }
      cached(:python_version) { 'python_version' }
      cached(:user) { 'a_user' }
      cached(:requirements_path) { 'requirements_path' }

      context "with requirements" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['activate_virtual_env'])
          ConvergeActivateVirtualEnv.run(runner, pyenv_name: pyenv_name, pyenv_path: pyenv_path, python_version: python_version, user: user, requirements: requirements_path)
        end
        cached(:node) { chef_run.node }

        it 'activates a virtual env' do
          is_expected.to run_activate_virtual_env('run')
        end

        it 'runs pyenv script' do
          is_expected.to run_pyenv_script("pyenv virtualenv #{pyenv_name}").with(
            code: "pyenv virtualenv #{python_version} #{pyenv_name}",
            user: user
          )
        end

        it 'upgrades pyenv pip' do
          is_expected.to upgrade_pyenv_pip("pip").with(
            virtualenv: pyenv_path,
            user: user
          )
        end

        it 'copies requirements file' do
          is_expected.to create_cookbook_file("#{pyenv_path}/requirements.txt").with(
            source: requirements_path,
            mode: '0755'
          )
        end

        it 'installs requirements in the virtual environment' do
          is_expected.to install_pyenv_pip("#{pyenv_path}/requirements.txt").with(
            virtualenv: pyenv_path,
            user: user,
            requirement: true
          )
        end
      end

      context "without requirements" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['activate_virtual_env'])
          ConvergeActivateVirtualEnv.run(runner, pyenv_name: pyenv_name, pyenv_path: pyenv_path, python_version: python_version, user: user)
        end
        cached(:node) { chef_run.node }

        it 'does not install requirements' do
          is_expected.not_to create_cookbook_file("#{pyenv_path}/requirements.txt")
          is_expected.not_to install_pyenv_pip("#{pyenv_path}/requirements.txt")
        end
      end
    end
  end
end
