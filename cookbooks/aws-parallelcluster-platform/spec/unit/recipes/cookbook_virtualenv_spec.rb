require 'spec_helper'

describe 'aws-parallelcluster-platform::cookbook_virtualenv' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:python_version) { 'python_version' }
      cached(:system_pyenv_root) { 'system_pyenv_root' }
      cached(:virtualenv_path) { 'system_pyenv_root/versions/python_version/envs/cookbook_virtualenv' }

      context "when cookbook virtualenv not installed yet" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['system_pyenv_root'] = system_pyenv_root
            node.override['cluster']['python-version'] = python_version
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'installs pyenv with default settings' do
          is_expected.to run_install_pyenv('pyenv for default python version')
        end

        it 'activates cookbook vistualenv' do
          is_expected.to run_activate_virtual_env('cookbook_virtualenv').with(
            pyenv_path: virtualenv_path,
            python_version: python_version
          )
        end

        it 'sets virtualenv path' do
          expect(node.default['cluster']['cookbook_virtualenv_path']).to eq(virtualenv_path)
          is_expected.to write_node_attributes('dump node attributes')
        end

        it 'copies requirements file' do
          is_expected.to create_cookbook_file("#{virtualenv_path}/requirements.txt").with(
            source: "cookbook_virtualenv/requirements.txt",
            mode: '0755'
          )
        end

        it 'installs python packages' do
          is_expected.to run_bash("pip install").with(
            user: 'root',
            group: 'root',
            cwd: "#{node['cluster']['base_dir']}"
          ).with_code(/tar xzf cookbook-dependencies.tgz/)
        end
      end
    end
  end
end
