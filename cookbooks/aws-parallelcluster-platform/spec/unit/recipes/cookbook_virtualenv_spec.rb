require 'spec_helper'

describe 'aws-parallelcluster-platform::cookbook_virtualenv' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:python_version) { 'python_version' }
      cached(:python_major_minor_version) { 'python_major_minor_version' }
      cached(:system_pyenv_root) { 'system_pyenv_root' }
      cached(:virtualenv_path) { 'system_pyenv_root/versions/python_version/envs/cookbook_virtualenv' }
      cached(:aws_region) { 'any-region' }
      cached(:base_dir) { '/opt/parallelcluster' }
      cached(:s3_url) { 's3://url' }
      cached(:arch) { 'x86_64' }
      cached(:dependency_package_name) { "pypi-cookbook-dependencies-#{python_major_minor_version}-#{arch}" }
      cached(:pip_install_s3_bash_code) do
        <<-REQ
      set -e
      tar xzf cookbook-dependencies.tgz
      cd #{dependency_package_name}
      #{virtualenv_path}/bin/pip install * -f ./ --no-index
        REQ
      end
      cached(:pip_install_internet_bash_code) do
        <<-REQ
      set -e
      #{virtualenv_path}/bin/pip install -r #{base_dir}/cookbook-requirements.txt
        REQ
      end

      context "when cookbook virtualenv not installed yet" do
        [true, false].each do |install_from_internet|
          context "when install_python_from_internet is #{install_from_internet}" do
            cached(:chef_run) do
              runner = runner(platform: platform, version: version) do |node|
                allow_any_instance_of(Object).to receive(:aws_region).and_return(aws_region)
                node.override['cluster']['system_pyenv_root'] = system_pyenv_root
                node.override['cluster']['python-version'] = python_version
                node.override['cluster']['python-major-minor-version'] = python_major_minor_version
                node.override['cluster']['region'] = aws_region
                node.override['cluster']['base_dir'] = base_dir
                node.override['cluster']['artifacts_s3_url'] = s3_url
                node.override['kernel']['machine'] = arch
                node.override['cluster']['install_python_from_internet'] = install_from_internet
              end
              runner.converge(described_recipe)
            end
            cached(:node) { chef_run.node }

            it 'installs pyenv with default settings' do
              is_expected.to run_install_pyenv('pyenv for default python version')
            end

            it 'activates cookbook virtualenv' do
              is_expected.to run_activate_virtual_env('cookbook_virtualenv').with(
                pyenv_path: virtualenv_path,
                python_version: python_version
              )
            end

            it 'sets virtualenv path' do
              expect(node.default['cluster']['cookbook_virtualenv_path']).to eq(virtualenv_path)
              is_expected.to write_node_attributes('dump node attributes')
            end

            if install_from_internet
              it 'does not download cookbook dependencies from S3' do
                is_expected.not_to create_remote_file("#{base_dir}/cookbook-dependencies.tgz")
              end

              it 'does not install python packages from S3' do
                is_expected.not_to run_bash("pip install cookbook dependencies from S3")
                  .with(user: 'root', group: 'root', cwd: base_dir)
                  .with(code: pip_install_s3_bash_code)
              end

              it 'creates cookbook requirements file' do
                is_expected.to create_cookbook_file("#{base_dir}/cookbook-requirements.txt")
              end

              it 'installs python packages from internet' do
                is_expected.to run_bash("pip install cookbook dependencies from internet")
                  .with(user: 'root', group: 'root')
                  .with(code: pip_install_internet_bash_code)
              end
            else
              it 'downloads cookbook dependencies from S3' do
                is_expected.to create_remote_file_if_missing("#{base_dir}/cookbook-dependencies.tgz")
              end

              it 'installs python packages from S3' do
                is_expected.to run_bash("pip install cookbook dependencies from S3")
                  .with(user: 'root', group: 'root', cwd: base_dir)
                  .with(code: pip_install_s3_bash_code)
              end

              it 'does not create cookbook requirements file' do
                is_expected.not_to create_cookbook_file("#{base_dir}/cookbook-requirements.txt")
              end

              it 'does not install python packages from internet' do
                is_expected.not_to run_bash("pip install cookbook dependencies from internet")
                  .with(user: 'root', group: 'root')
                  .with(code: pip_install_internet_bash_code)
              end
            end
          end
        end
      end
    end
  end
end
