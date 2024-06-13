require 'spec_helper'

describe 'aws-parallelcluster-platform::cuda' do
  cached(:cuda_version) { '12.2' }
  cached(:cuda_patch) { '2' }
  cached(:cuda_complete_version) { "#{cuda_version}.#{cuda_patch}" }
  cached(:cuda_version_suffix) { '535.104.05' }

  context 'when nvidia not enabled' do
    cached(:chef_run) do
      allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
      ChefSpec::Runner.new.converge(described_recipe)
    end

    it 'does not install cuda' do
      is_expected.not_to run_bash('cuda.run advanced')
    end
  end

  context 'when on arm' do
    cached(:cuda_arch) { 'linux_sbsa' }
    cached(:cuda_url) { "https://developer.download.nvidia.com/compute/cuda/#{cuda_complete_version}/local_installers/cuda_#{cuda_complete_version}_#{cuda_version_suffix}_#{cuda_arch}.run" }
    cached(:cuda_samples_version) { '12.2' }
    cached(:cuda_samples_url) { "https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v#{cuda_samples_version}.tar.gz" }

    cached(:chef_run) do
      allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
      allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
      allow(::File).to receive(:exist?).with("/usr/local/cuda-#{cuda_version}").and_return(false)
      allow(::File).to receive(:exist?).with("/usr/local/cuda-#{cuda_version}/samples").and_return(false)
      ChefSpec::Runner.new.converge(described_recipe)
    end
    cached(:node) { chef_run.node }

    it 'saves cuda and cuda samples version' do
      expect(node['cluster']['nvidia']['cuda']['version']).to eq(cuda_version)
      expect(node['cluster']['nvidia']['cuda_samples_version']).to eq(cuda_samples_version)
      is_expected.to write_node_attributes('Save cuda and cuda samples versions for InSpec tests')
    end

    it 'downloads CUDA run file' do
      is_expected.to create_remote_file('/tmp/cuda.run').with(
        source: cuda_url,
        mode: '0755',
        retries: 3,
        retry_delay: 5
      )
    end

    it 'installs CUDA driver' do
      # Install CUDA driver
      is_expected.to run_bash('cuda.run advanced')
        .with(
          user: 'root',
          group: 'root',
          cwd: '/tmp',
          creates: "/usr/local/cuda-#{cuda_version}")
        .with_code(%r{mkdir /cuda-install})
        .with_code(%r{./cuda.run --silent --toolkit --samples --tmpdir=/cuda-install})
        .with_code(%r{rm -rf /cuda-install})
        .with_code(%r{rm -f /tmp/cuda.run})
    end

    it 'downloads CUDA sample files' do
      is_expected.to create_remote_file('/tmp/cuda-sample.tar.gz').with(
        source: cuda_samples_url,
        mode: '0644',
        retries: 3,
        retry_delay: 5
      )
    end

    it 'unpacks CUDA samples' do
      is_expected.to run_bash('cuda.sample install')
        .with(
          user: 'root',
          group: 'root',
          cwd: '/tmp')
        .with_code(%r{tar xf "/tmp/cuda-sample.tar.gz" --directory "/usr/local/"})
        .with_code(%r{rm -f "/tmp/cuda-sample.tar.gz"})
    end
  end

  context 'when not on arm' do
    cached(:cuda_arch) { 'linux' }
    cached(:cuda_url) { "https://developer.download.nvidia.com/compute/cuda/#{cuda_complete_version}/local_installers/cuda_#{cuda_complete_version}_#{cuda_version_suffix}_#{cuda_arch}.run" }

    cached(:chef_run) do
      allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
      allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
      allow(::File).to receive(:exist?).with("/usr/local/cuda-#{cuda_version}").and_return(false)
      allow(::File).to receive(:exist?).with("/usr/local/cuda-#{cuda_version}/samples").and_return(false)
      ChefSpec::Runner.new.converge(described_recipe)
    end
    cached(:node) { chef_run.node }

    it 'downloads CUDA run file' do
      is_expected.to create_remote_file('/tmp/cuda.run').with_source(cuda_url)
    end
  end
end
