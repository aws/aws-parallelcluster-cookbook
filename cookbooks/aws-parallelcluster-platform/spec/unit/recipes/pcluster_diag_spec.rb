require 'spec_helper'

describe 'aws-parallelcluster-platform::pcluster_diag' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:python_version) { 'python_version' }
      cached(:system_pyenv_root) { 'system_pyenv_root' }
      cached(:virtualenv_path) { 'system_pyenv_root/versions/python_version/envs/cookbook_virtualenv' }
      cached(:aws_region) { 'any-region' }
      cached(:base_dir) { '/opt/parallelcluster' }
      cached(:sources_dir) { '/opt/parallelcluster/sources' }
      cached(:source_dir) { "#{sources_dir}/pcluster-diag" }
      cached(:bin_path) { '/usr/local/bin/pcluster-diag' }
      cached(:wrapper_content) do
        <<~WRAPPER
          #!/bin/sh
          export PYTHONPATH="#{source_dir}"
          exec #{virtualenv_path}/bin/python -m pcluster_diag.cli "$@"
        WRAPPER
      end

      context "when installing the diagnostics tool" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            allow_any_instance_of(Object).to receive(:aws_region).and_return(aws_region)
            node.override['cluster']['system_pyenv_root'] = system_pyenv_root
            node.override['cluster']['python-version'] = python_version
            node.override['cluster']['region'] = aws_region
            node.override['cluster']['base_dir'] = base_dir
            node.override['cluster']['sources_dir'] = sources_dir
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'stages the tool source from the cookbook' do
          is_expected.to create_remote_directory(source_dir).with(
            source: 'pcluster-diag',
            recursive: true
          )
        end

        it 'creates a wrapper on PATH that runs the tool from source with the cookbook_virtualenv interpreter' do
          is_expected.to create_template(bin_path)
            .with(owner: 'root', group: 'root', mode: '0744')
          is_expected.to render_file(bin_path).with_content(wrapper_content)
        end
      end
    end
  end
end
