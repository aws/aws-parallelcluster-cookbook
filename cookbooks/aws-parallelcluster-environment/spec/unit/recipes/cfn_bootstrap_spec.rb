require 'spec_helper'

describe 'aws-parallelcluster-environment::cfn_bootstrap' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:arch) { 'x86_64' }
      cached(:s3_url) { 's3://url' }
      cached(:base_dir) { 'base_dir' }
      cached(:python_version) { "#{node['cluster']['python-version']}" }
      cached(:dependecy_package_name_suffix) { "pypi-cfn-dependencies-#{node['cluster']['python-major-minor-version']}-#{arch}" }
      cached(:dependecy_folder_name) { dependecy_package_name_suffix }
      cached(:cfnbootstrap_package) { "aws-cfn-bootstrap-py3-#{node['cluster']['cfn_bootstrap']['version']}.tar.gz" }
      cached(:system_pyenv_root) { 'system_pyenv_root' }
      cached(:virtualenv_path) { "system_pyenv_root/versions/#{python_version}/envs/cfn_bootstrap_virtualenv" }
      cached(:timeout) { 1800 }
      cached(:dependency_bash_code) do
        <<-REQ
      set -e
      tar xzf cfn-dependencies.tgz
      cd #{dependecy_folder_name}
      #{virtualenv_path}/bin/pip install * -f ./ --no-index
        REQ
      end

      context "when cfn_bootstrap virtualenv not installed yet" do
        [true, false].each do |install_from_internet|
          context "when install_python_from_internet is #{install_from_internet}" do
            cached(:pip_install_flags) { install_from_internet ? "" : "--no-build-isolation" }
            cached(:cfn_install_command) do
              cmd = "#{virtualenv_path}/bin/pip install #{cfnbootstrap_package}"
              cmd += " #{pip_install_flags}" unless pip_install_flags.empty?
              cmd
            end

            cached(:chef_run) do
              runner = runner(platform: platform, version: version) do |node|
                node.override['cluster']['system_pyenv_root'] = system_pyenv_root
                node.override['cluster']['region'] = 'non_china'
                node.override['cluster']['base_dir'] = base_dir
                node.override['cluster']['compute_node_bootstrap_timeout'] = timeout
                node.override['cluster']['artifacts_s3_url'] = s3_url
                node.override['kernel']['machine'] = arch
                node.override['cluster']['install_python_from_internet'] = install_from_internet
              end
              runner.converge(described_recipe)
            end
            cached(:node) { chef_run.node }

            it 'installs pyenv for specific python version' do
              is_expected.to run_install_pyenv('pyenv for cfn_bootstrap').with_python_version(python_version)
            end

            it 'activates cfn_bootstrap virtualenv' do
              is_expected.to run_activate_virtual_env('cfn_bootstrap_virtualenv').with(
                pyenv_path: virtualenv_path,
                python_version: python_version
              )
            end

            it 'sets virtualenv path' do
              expect(node.default['cluster']['cfn_bootstrap_virtualenv_path']).to eq(virtualenv_path)
              is_expected.to write_node_attributes('dump node attributes')
            end

            it 'downloads cfn_bootstrap package from s3' do
              is_expected.to create_remote_file("base_dir/tmp/#{cfnbootstrap_package}").with(
                source: "https://s3.amazonaws.com/cloudformation-examples/#{cfnbootstrap_package}"
              )
            end

            it 'installs package in cfn_bootstrap virtualenv' do
              is_expected.to run_bash("Install CloudFormation helpers from #{cfnbootstrap_package}").with(
                user: 'root',
                group: 'root',
                cwd: 'base_dir/tmp',
                code: cfn_install_command,
                creates: "#{virtualenv_path}/bin/cfn-hup"
              )
            end

            it 'adds cfn_bootstrap virtualenv to a cookbook profile' do
              is_expected.to create_template("#{node['cluster']['etc_dir']}/pcluster_cookbook_environment.sh").with(
                source: "cfn_bootstrap/pcluster_cookbook_environment.sh.erb",
                owner: 'root',
                group: 'root',
                mode: '0644',
                variables: { cfn_bootstrap_virtualenv_path: virtualenv_path }
              )
            end

            it 'creates scripts_dir if not yet existing' do
              is_expected.to create_directory(node['cluster']['scripts_dir']).with_recursive(true)
            end

            it 'adds cfn-hup runner' do
              is_expected.to create_template("#{node['cluster']['scripts_dir']}/cfn-hup-runner.sh").with(
                source: "cfn_hup_configuration/cfn-hup-runner.sh.erb",
                owner: 'root',
                group: 'root',
                mode: '0744',
                variables: { cfn_bootstrap_virtualenv_path: virtualenv_path, node_bootstrap_timeout: timeout }
              )
            end

            if install_from_internet
              it 'does not download cfn_dependencies package from S3' do
                is_expected.not_to create_remote_file("#{base_dir}/cfn-dependencies.tgz")
              end

              it 'does not pip install dependencies from S3' do
                is_expected.not_to run_bash('pip install cfn dependencies from S3')
                  .with(user: 'root')
                  .with(group: 'root')
                  .with(cwd: base_dir)
                  .with(code: dependency_bash_code)
              end
            else
              it 'downloads cfn_dependencies package from s3' do
                is_expected.to create_if_missing_remote_file("#{base_dir}/cfn-dependencies.tgz")
                  .with(source: "#{s3_url}/dependencies/PyPi/#{arch}/#{dependecy_package_name_suffix}.tgz")
                  .with(mode: '0644')
                  .with(retries: 3)
                  .with(retry_delay: 5)
              end

              it 'pip installs dependencies from S3' do
                is_expected.to run_bash('pip install cfn dependencies from S3')
                  .with(user: 'root')
                  .with(group: 'root')
                  .with(cwd: base_dir)
                  .with(code: dependency_bash_code)
              end
            end
          end
        end
      end

      context "when cfn_bootstrap virtualenv already installed" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['system_pyenv_root'] = system_pyenv_root
            node.override['cluster']['python-version'] = python_version
          end
          allow(File).to receive(:exist?).with("#{virtualenv_path}/bin/activate").and_return(true)
          runner.converge(described_recipe)
        end

        it 'does not activate cfn_bootstrap virtualenv' do
          is_expected.not_to run_activate_virtual_env('cfn_bootstrap_virtualenv')
        end
      end

      context "when run in China" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['system_pyenv_root'] = system_pyenv_root
            node.override['cluster']['python-version'] = python_version
            node.override['cluster']['base_dir'] = base_dir
            node.override['cluster']['region'] = 'cn-something'
          end
          runner.converge(described_recipe)
        end
        it 'downloads cfn_bootstrap package from a different s3 bucket' do
          is_expected.to create_remote_file("base_dir/tmp/#{cfnbootstrap_package}").with(
            source: "https://s3.cn-north-1.amazonaws.com.cn/cn-north-1-aws-parallelcluster/cloudformation-examples/#{cfnbootstrap_package}"
          )
        end
      end
    end
  end
end
