require 'spec_helper'

describe 'aws-parallelcluster-environment::cfn_bootstrap' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:cfnbootstrap_version) { '2.0-28' }
      cached(:cfnbootstrap_package) { "aws-cfn-bootstrap-py3-#{cfnbootstrap_version}.tar.gz" }
      cached(:python_version) { '3.9.19' }
      cached(:system_pyenv_root) { 'system_pyenv_root' }
      cached(:virtualenv_path) { "system_pyenv_root/versions/#{python_version}/envs/cfn_bootstrap_virtualenv" }

      context "when cfn_bootstrap virtualenv not installed yet" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['system_pyenv_root'] = system_pyenv_root
            node.override['cluster']['region'] = 'non_china'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'installs pyenv for specific python version' do
          is_expected.to run_install_pyenv('pyenv for cfn_bootstrap').with_python_version(python_version)
        end

        it 'activates cookbook vistualenv' do
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
          is_expected.to create_remote_file("/tmp/#{cfnbootstrap_package}").with(
            source: "https://s3.amazonaws.com/cloudformation-examples/#{cfnbootstrap_package}"
          )
        end

        it 'installs package in cfn_bootstrap virtualenv' do
          is_expected.to run_bash("Install CloudFormation helpers from #{cfnbootstrap_package}").with(
            user: 'root',
            group: 'root',
            cwd: '/tmp',
            code: "#{virtualenv_path}/bin/pip install #{cfnbootstrap_package}",
            creates: "#{virtualenv_path}/bin/cfn-hup"
          )
        end

        it 'adds cfn_bootstrap virtualenv to default path' do
          is_expected.to create_template("/etc/profile.d/pcluster.sh").with(
            source: "cfn_bootstrap/pcluster.sh.erb",
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
            source: "cfn_bootstrap/cfn-hup-runner.sh.erb",
            owner: 'root',
            group: 'root',
            mode: '0744',
            variables: { cfn_bootstrap_virtualenv_path: virtualenv_path }
          )
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
            node.override['cluster']['region'] = 'cn-something'
          end
          runner.converge(described_recipe)
        end
        it 'downloads cfn_bootstrap package from a different s3 bucket' do
          is_expected.to create_remote_file("/tmp/#{cfnbootstrap_package}").with(
            source: "https://s3.cn-north-1.amazonaws.com.cn/cn-north-1-aws-parallelcluster/cloudformation-examples/#{cfnbootstrap_package}"
          )
        end
      end
    end
  end
end
