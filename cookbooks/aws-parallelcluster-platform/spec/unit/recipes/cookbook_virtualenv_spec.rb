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
            python_version: python_version,
            requirements_path: "cookbook_virtualenv/requirements.txt"
          )
        end

        it 'sets virtualenv path' do
          expect(node.default['cluster']['cookbook_virtualenv_path']).to eq(virtualenv_path)
          is_expected.to write_node_attributes('dump node attributes')
        end
      end

      context "when cookbook virtualenv already installed" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['system_pyenv_root'] = system_pyenv_root
            node.override['cluster']['python-version'] = python_version
          end
          allow(File).to receive(:exist?).with("#{virtualenv_path}/bin/activate").and_return(true)
          runner.converge(described_recipe)
        end

        it 'does not activate cookbook virtualenv' do
          is_expected.not_to run_activate_virtual_env('cookbook_virtualenv')
        end
      end
    end
  end
end
