require 'spec_helper'

describe 'aws-parallelcluster-computefleet::custom_parallelcluster_node' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:s3_url) { 's3://url' }
      cached(:base_dir) { 'base_dir' }
      cached(:arch) { 'x86_64' }
      cached(:region) { 'any-region' }
      cached(:python_version) { 'python_version' }
      cached(:dependency_pkg_name_suffix) do
        if platform == 'amazon' && version == '2'
          'node-dependencies'
        else
          "pypi-node-dependencies-#{python_version}-#{arch}"
        end
      end
      cached(:dependency_folder_name_suffix) do
        if platform == 'amazon' && version == '2'
          "node"
        else
          dependency_pkg_name_suffix
        end
      end
      cached(:virtualenv_path) { "#{base_dir}/pyenv/versions/#{python_version}/envs/node_virtualenv" }
      cached(:cookbook_virtualenv_path) { "#{base_dir}/pyenv/versions/#{python_version}/envs/cookbook_virtualenv" }
      cached(:custom_node_s3_url) { "#{s3_url}/pyenv/versions/#{python_version}/envs/node_virtualenv" }
      cached(:pip_install_bash_code) do
        <<-REQ
  set -e
  tar xzf node-dependencies.tgz
  cd #{dependency_folder_name_suffix}
  #{virtualenv_path}/bin/pip install * -f ./ --no-index
        REQ
      end
      cached(:node_bash_code) do
        <<-NODE
  set -e
  [[ ":$PATH:" != *":/usr/local/bin:"* ]] && PATH="/usr/local/bin:${PATH}"
  echo "PATH is $PATH"
  source #{virtualenv_path}/bin/activate
  pip uninstall --yes aws-parallelcluster-node
  if [[ "#{custom_node_s3_url}" =~ ^s3:// ]]; then
    custom_package_url=$(#{cookbook_virtualenv_path}/bin/aws s3 presign #{custom_node_s3_url} --region #{region})
  else
    custom_package_url=#{custom_node_s3_url}
  fi
  curl --retry 3 -L -o aws-parallelcluster-node.tgz ${custom_package_url}
  rm -fr aws-parallelcluster-custom-node
  mkdir aws-parallelcluster-custom-node
  tar -xzf aws-parallelcluster-node.tgz --directory aws-parallelcluster-custom-node
  cd aws-parallelcluster-custom-node/*aws-parallelcluster-node*
  pip install . --no-build-isolation
  deactivate
        NODE
      end
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          node.override['kernel']['machine'] = arch
          node.override['cluster']['python-major-minor-version'] = python_version
          node.override['cluster']['python-version'] = python_version
          node.override['cluster']['base_dir'] = base_dir
          node.override['cluster']['region'] = region
          node.override['cluster']['artifacts_s3_url'] = s3_url
          node.override['cluster']['custom_node_package'] = custom_node_s3_url
        end
        allow(File).to receive(:exist?).with("#{virtualenv_path}/bin/activate").and_return(true)
        runner.converge(described_recipe)
      end

      it 'downloads tarball' do
        is_expected.to create_if_missing_remote_file("base_dir/node-dependencies.tgz")
          .with(source: "#{s3_url}/dependencies/PyPi/#{arch}/#{dependency_pkg_name_suffix}.tgz")
          .with(mode: '0644')
          .with(retries: 3)
          .with(retry_delay: 5)
      end

      it 'pip installs' do
        is_expected.to run_bash('pip install')
          .with(cwd: base_dir)
          .with(code: pip_install_bash_code.gsub(/^  /, '    '))
      end

      it 'install custom aws-parallelcluster-node' do
        is_expected.to run_bash('install custom aws-parallelcluster-node')
          .with(code: node_bash_code.gsub(/^  /, '    '))
      end
    end
  end
end
