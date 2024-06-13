require 'spec_helper'

class ConvergeInstallPyenv
  def self.run(chef_run, python_version: nil, pyenv_root: nil, user_only: nil, user: nil)
    chef_run.converge_dsl('aws-parallelcluster-shared') do
      install_pyenv 'run' do
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
          runner = runner(platform: platform, version: version, step_into: ['install_pyenv']) do |node|
            node.override['cluster']['system_pyenv_root'] = system_pyenv_root
            node.override['cluster']['python-version'] = python_version
            node.override['cluster']['artifacts_s3_url'] = "https://bucket.s3.#{aws_domain}/archives"
          end
          ConvergeInstallPyenv.run(runner)
        end
        cached(:node) { chef_run.node }

        it 'runs install_pyenv' do
          is_expected.to run_install_pyenv('run')
        end

        it 'creates pyenv root dir' do
          is_expected.to create_directory(system_pyenv_root).with_recursive(true)
        end

        it 'downloads python tarball' do
          is_expected.to create_if_missing_remote_file("#{node['cluster']['system_pyenv_root']}/Python-#{python_version}.tgz").with(
            source: "#{node['cluster']['artifacts_s3_url']}/dependencies/python/Python-#{python_version}.tgz",
            mode: '0644',
            retries: 3,
            retry_delay: 5
          )
        end

        it 'installs python' do
          is_expected.to run_bash("install python #{python_version}").with(
            user: 'root',
            group: 'root',
            cwd: "#{node['cluster']['system_pyenv_root']}"
          ).with_code(/tar -xzf Python-#{python_version}.tgz/)
                                                                     .with_code(%r{./configure --prefix=#{node['cluster']['system_pyenv_root']}/versions/#{python_version}})
        end
      end

      context "when python version and pyenv root are set" do
        cached(:python_version) { 'python_version_parameter' }
        cached(:system_pyenv_root) { 'pyenv_root_parameter' }
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: 'install_pyenv') do |node|
            node.override['cluster']['system_pyenv_root'] = 'default_system_pyenv_root'
            node.override['cluster']['python-version'] = 'default_python_version'
          end
          ConvergeInstallPyenv.run(runner, python_version: python_version, pyenv_root: system_pyenv_root)
        end
        cached(:node) { chef_run.node }

        it 'creates pyenv root dir' do
          is_expected.to create_directory(system_pyenv_root).with_recursive(true)
        end

        it 'downloads python tarball' do
          is_expected.to create_if_missing_remote_file("#{system_pyenv_root}/Python-#{python_version}.tgz").with(
            source: "https://www.python.org/ftp/python/#{python_version}/Python-#{python_version}.tgz",
            mode: '0644',
            retries: 3,
            retry_delay: 5
          )
        end

        it 'installs python' do
          is_expected.to run_bash("install python #{python_version}").with(
            user: 'root',
            group: 'root',
            cwd: "#{system_pyenv_root}"
          )
        end
      end

      context "when it is a user only installation" do
        context "and user is not set" do
          cached(:chef_run) do
            runner(platform: platform, version: version, step_into: ['install_pyenv'])
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
            runner = runner(platform: platform, version: version, step_into: ['install_pyenv']) do |node|
              node.override['cluster']['python-version'] = python_version
              node.override['cluster']['artifacts_s3_url'] = "https://bucket.s3.#{aws_domain}/archives"
            end
            # ConvergeInstallPyenv.run(runner)
            # runner = runner(platform: platform, version: version, step_into: ['install_pyenv'])
            ConvergeInstallPyenv.run(runner, user_only: true, user: user, python_version: python_version, pyenv_root: pyenv_root)
          end

          it 'downloads python tarball' do
            is_expected.to create_if_missing_remote_file("#{pyenv_root}/Python-#{python_version}.tgz").with(
              source: "https://www.python.org/ftp/python/#{python_version}/Python-#{python_version}.tgz",
              mode: '0644',
              retries: 3,
              retry_delay: 5
            )
          end

          it 'installs python' do
            is_expected.to run_bash("install python #{python_version}").with(
              user: user,
              group: 'root',
              cwd: "#{pyenv_root}"
            )
          end
        end
      end
    end
  end
end