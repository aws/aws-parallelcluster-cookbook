require 'spec_helper'

class ConvergeNvidiaCuda
  def self.setup(chef_run, cuda_version: nil)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      nvidia_cuda 'setup' do
        cuda_version cuda_version unless cuda_version.nil?
        action :setup
      end
    end
  end
end

describe 'nvidia_cuda helpers' do
  cached(:cuda_version) { '1.2.3' }

  cached(:chef_run) do
    allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
    ChefSpec::SoloRunner.new(step_into: ['nvidia_cuda']) do |node|
      node.override['cluster']['nvidia']['cuda']['version'] = cuda_version
    end
  end
  cached(:resource) do
    ConvergeNvidiaCuda.setup(chef_run)
    chef_run.find_resource('nvidia_cuda', 'setup')
  end

  it 'takes the cuda version from the attribute' do
    expect(resource.cuda_version).to eq(cuda_version)
  end

  it 'computes the cuda major.minor form' do
    expect(resource.cuda_major_minor).to eq('1.2')
  end

  it 'computes the cuda toolkit package name' do
    expect(resource.cuda_toolkit_package).to eq('cuda-toolkit-1-2')
  end

  it 'computes the install dir, samples dir and path' do
    expect(resource.cuda_installation_base_dir).to eq('/usr/local')
    expect(resource.cuda_install_dir).to eq('/usr/local/cuda-1.2')
    expect(resource.cuda_samples_dir).to eq('/usr/local/cuda-1.2/samples')
    expect(resource.cuda_path).to eq('/usr/local/cuda')
  end

  it 'computes the samples archive and url' do
    expect(resource.cuda_samples_archive).to eq('/tmp/cuda-sample.tar.gz')
    expect(resource.cuda_samples_url).to eq("#{resource.node['cluster']['nvidia']['cuda']['samples_base_url']}/v1.2.tar.gz")
  end
end

describe 'nvidia_cuda: overriding samples_base_url to the official NVIDIA URL' do
  cached(:cuda_version) { '1.2.3' }
  cached(:samples_base_url) { 'https://github.com/NVIDIA/cuda-samples/archive/refs/tags' }

  cached(:chef_run) do
    allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
    allow_any_instance_of(Object).to receive(:on_docker?).and_return(false)
    mock_file_exists('/usr/local/cuda', false)
    mock_file_exists('/usr/local/cuda-1.2/samples', false)
    runner = runner(platform: 'amazon', version: '2023', step_into: ['nvidia_cuda']) do |node|
      node.override['cluster']['nvidia']['cuda']['version'] = cuda_version
      node.override['cluster']['nvidia']['cuda']['samples_base_url'] = samples_base_url
    end
    ConvergeNvidiaCuda.setup(runner)
  end

  it 'downloads the cuda samples from the official NVIDIA URL' do
    is_expected.to create_remote_file('/tmp/cuda-sample.tar.gz').with(
      source: "#{samples_base_url}/v1.2.tar.gz"
    )
  end
end

describe 'nvidia_cuda:setup' do
  for_all_oses do |platform, version|
    cached(:cuda_version) { '1.2.3' }

    context "on #{platform}#{version} when nvidia not enabled" do
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
        runner = runner(platform: platform, version: version, step_into: ['nvidia_cuda']) do |node|
          node.override['cluster']['nvidia']['cuda']['version'] = cuda_version
        end
        ConvergeNvidiaCuda.setup(runner)
      end

      it 'does not install the cuda toolkit' do
        is_expected.not_to install_package('cuda-toolkit-1-2')
      end
    end

    context "on #{platform}#{version} when cuda is already installed" do
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
        allow_any_instance_of(Object).to receive(:on_docker?).and_return(false)
        mock_file_exists('/usr/local/cuda', true)
        runner = runner(platform: platform, version: version, step_into: ['nvidia_cuda']) do |node|
          node.override['cluster']['nvidia']['cuda']['version'] = cuda_version
        end
        ConvergeNvidiaCuda.setup(runner)
      end

      it 'skips the entire cuda setup' do
        is_expected.not_to install_package('cuda-toolkit-1-2')
        is_expected.not_to create_remote_file('/tmp/cuda-sample.tar.gz')
        is_expected.not_to create_template('/etc/profile.d/cuda.sh')
        is_expected.not_to write_node_attributes('Save cuda and cuda samples versions for InSpec tests')
      end
    end

    context "on #{platform}#{version} when cuda is not yet installed" do
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
        allow_any_instance_of(Object).to receive(:on_docker?).and_return(false)
        mock_file_exists('/usr/local/cuda', false)
        mock_file_exists('/usr/local/cuda-1.2/samples', false)
        runner = runner(platform: platform, version: version, step_into: ['nvidia_cuda']) do |node|
          node.override['cluster']['nvidia']['cuda']['version'] = cuda_version
        end
        ConvergeNvidiaCuda.setup(runner)
      end
      cached(:node) { chef_run.node }

      it 'sets up nvidia_cuda' do
        is_expected.to setup_nvidia_cuda('setup')
      end

      it 'shares the cuda versions for InSpec' do
        is_expected.to write_node_attributes('Save cuda and cuda samples versions for InSpec tests')
        expect(node['cluster']['nvidia']['cuda']['major_minor_version']).to eq('1.2')
        expect(node['cluster']['nvidia']['cuda_samples_version']).to eq('1.2')
      end

      it 'leaves the canonical cuda version attribute untouched (full version)' do
        expect(node['cluster']['nvidia']['cuda']['version']).to eq(cuda_version)
      end

      it 'renders the cuda.sh profile with the cuda path' do
        is_expected.to create_template('/etc/profile.d/cuda.sh').with(
          source: 'nvidia/cuda.sh.erb',
          cookbook: 'aws-parallelcluster-platform',
          variables: { cuda_path: '/usr/local/cuda' }
        )
      end

      it 'downloads and unpacks the cuda samples' do
        is_expected.to create_remote_file('/tmp/cuda-sample.tar.gz')
        is_expected.to run_bash('cuda.sample install').with(
          creates: '/usr/local/cuda-1.2/samples'
        )
      end

      it 'installs the cuda toolkit via the platform package manager' do
        is_expected.to install_package('cuda-toolkit-1-2').with(
          retries: 3,
          retry_delay: 5
        )
      end
    end
  end
end
