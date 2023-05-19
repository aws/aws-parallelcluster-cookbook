require 'spec_helper'

describe 'aws-parallelcluster-computefleet::node' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:node_version) { 'node_version' }
      cached(:python_version) { 'python_version' }
      cached(:system_pyenv_root) { 'system_pyenv_root' }
      cached(:virtualenv_path) { 'system_pyenv_root/versions/python_version/envs/node_virtualenv' }

      context "when node virtualenv not installed yet and custom node package is not set" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['system_pyenv_root'] = system_pyenv_root
            node.override['cluster']['python-version'] = python_version
            node.override['cluster']['parallelcluster-node-version'] = node_version
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'installs pyenv with default settings' do
          is_expected.to run_install_pyenv('pyenv for default python version')
        end

        it 'activates cookbook vistualenv' do
          is_expected.to run_activate_virtual_env('node_virtualenv').with(
            pyenv_path: virtualenv_path,
            python_version: python_version
          )
        end

        it 'sets virtualenv path' do
          expect(node.default['cluster']['node_virtualenv_path']).to eq(virtualenv_path)
          is_expected.to write_node_attributes('dump node attributes')
        end

        it 'installs official node package' do
          is_expected.to install_pyenv_pip('aws-parallelcluster-node').with(
            version: node_version,
            virtualenv: virtualenv_path
          )
        end
      end

      context "when node virtualenv already installed" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['system_pyenv_root'] = system_pyenv_root
            node.override['cluster']['python-version'] = python_version
          end
          allow(File).to receive(:exist?).with("#{virtualenv_path}/bin/activate").and_return(true)
          runner.converge(described_recipe)
        end

        it 'does not activate node virtualenv' do
          is_expected.not_to run_activate_virtual_env('node_virtualenv')
        end
      end

      context "when custom node package is specified" do
        cached(:custom_node_package) { 'custom_node_package' }
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['system_pyenv_root'] = system_pyenv_root
            node.override['cluster']['python-version'] = python_version
            node.override['cluster']['custom_node_package'] = custom_node_package
          end
          runner.converge(described_recipe)
        end

        it 'installs custom node package' do
          is_expected.to run_bash('install aws-parallelcluster-node')
            .with_code(/custom_package_url=.*#{custom_node_package}/)
            .with_code(%r{source #{virtualenv_path}/bin/activate})
        end
      end
    end
  end
end
