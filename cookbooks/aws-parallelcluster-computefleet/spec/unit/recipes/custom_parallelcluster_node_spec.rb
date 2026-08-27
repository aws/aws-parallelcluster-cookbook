require 'spec_helper'

describe 'aws-parallelcluster-computefleet::custom_parallelcluster_node' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:s3_url) { 's3://url' }
      cached(:base_dir) { 'base_dir' }
      cached(:arch) { 'x86_64' }
      cached(:region) { 'any-region' }
      cached(:python_version) { 'python_version' }
      cached(:dependency_pkg_name_suffix) { "pypi-node-dependencies-#{python_version}-#{arch}" }
      cached(:dependency_folder_name_suffix) { dependency_pkg_name_suffix }
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

      [true, false].each do |install_from_internet|
        context "when install_python_from_internet is #{install_from_internet}" do
          cached(:pip_install_flags) { install_from_internet ? "" : "--no-build-isolation" }
          cached(:node_bash_code) do
            <<-NODE
  set -e
  [[ ":$PATH:" != *":/usr/local/bin:"* ]] && PATH="/usr/local/bin:${PATH}"
  echo "PATH is $PATH"
  source #{virtualenv_path}/bin/activate
  pip uninstall --yes aws-parallelcluster-node
  if [[ "#{custom_node_s3_url}" =~ ^s3:// ]]; then
    custom_package_url=$(#{cookbook_virtualenv_path}/bin/aws s3 presign #{custom_node_s3_url} --region test_region --endpoint-url https://s3.test_region.test_aws_domain)
  else
    custom_package_url=#{custom_node_s3_url}
  fi
  delays=(1 2 4 8 16 32 64 128 256)
  for i in {0..8}; do
    curl -v -L -o aws-parallelcluster-node.tgz ${custom_package_url} && break
    echo "Curl attempt $((i+1)) failed, retrying in ${delays[$i]}s..."
    sleep ${delays[$i]}
  done
  rm -fr aws-parallelcluster-custom-node
  mkdir aws-parallelcluster-custom-node
  tar -xzf aws-parallelcluster-node.tgz --directory aws-parallelcluster-custom-node
  cd aws-parallelcluster-custom-node/*aws-parallelcluster-node*
  pip install .#{pip_install_flags.empty? ? '' : ' ' + pip_install_flags}
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
              node.override['cluster']['install_python_from_internet'] = install_from_internet
            end
            allow(File).to receive(:exist?).with("#{virtualenv_path}/bin/activate").and_return(true)
            runner.converge(described_recipe)
          end

          if install_from_internet
            it 'does not download tarball from S3' do
              is_expected.not_to create_remote_file("base_dir/node-dependencies.tgz")
            end

            it 'does not pip install node dependencies from S3' do
              is_expected.not_to run_bash('pip install node dependencies from S3')
            end
          else
            it 'downloads tarball from S3' do
              is_expected.to create_if_missing_remote_file("base_dir/node-dependencies.tgz")
                .with(source: "#{s3_url}/dependencies/PyPi/#{arch}/#{dependency_pkg_name_suffix}.tgz")
                .with(mode: '0644')
                .with(retries: 3)
                .with(retry_delay: 5)
            end

            it 'pip installs node dependencies from S3' do
              is_expected.to run_bash('pip install node dependencies from S3')
                .with(cwd: base_dir)
                .with(code: pip_install_bash_code.gsub(/^  /, '    '))
            end
          end

          it 'installs aws-parallelcluster-node' do
            is_expected.to run_bash("install aws-parallelcluster-node from #{custom_node_s3_url}")
              .with(code: node_bash_code.gsub(/^  /, '    '))
          end
        end
      end
    end
  end
end
