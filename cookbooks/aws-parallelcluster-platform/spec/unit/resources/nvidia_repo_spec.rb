require 'spec_helper'

class ConvergeNvidiaRepo
  def self.add(chef_run, aws_region: 'any')
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      nvidia_repo 'add' do
        aws_region aws_region
        action :add
      end
    end
  end

  def self.remove(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      nvidia_repo 'remove' do
        action :remove
      end
    end
  end
end

describe 'nvidia_repo:domain' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: ['nvidia_repo'])
  end

  context 'when in China region' do
    cached(:resource) do
      ConvergeNvidiaRepo.add(chef_run, aws_region: 'cn-anything')
      chef_run.find_resource('nvidia_repo', 'add')
    end

    it 'is cn' do
      expect(resource.repo_domain).to eq('cn')
    end
  end

  context 'when in region other than China' do
    cached(:resource) do
      ConvergeNvidiaRepo.add(chef_run, aws_region: 'anything')
      chef_run.find_resource('nvidia_repo', 'add')
    end

    it 'is cn' do
      expect(resource.repo_domain).to eq('com')
    end
  end
end

describe 'nvidia_repo:arch_suffix' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: ['nvidia_repo'])
  end

  context 'when on arm' do
    cached(:resource) do
      allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
      ConvergeNvidiaRepo.add(chef_run)
      chef_run.find_resource('nvidia_repo', 'add')
    end

    it 'is sbsa' do
      expect(resource.arch_suffix).to eq('sbsa')
    end
  end

  context 'when on x86' do
    cached(:resource) do
      allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
      ConvergeNvidiaRepo.add(chef_run)
      chef_run.find_resource('nvidia_repo', 'add')
    end

    it 'is x86_64' do
      expect(resource.arch_suffix).to eq('x86_64')
    end
  end
end

describe 'nvidia_repo:add' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:repo_domain) { 'repo_domain' }
      cached(:arch_suffix) { 'arch_suffix' }
      cached(:nvidia_platform) do
        case platform
        when 'amazon', 'centos'
          'rhel7'
        when 'redhat', 'rocky'
          "rhel#{version.to_i}"
        when 'ubuntu'
          "ubuntu#{version.delete('.')}"
        end
      end
      cached(:repository_url) { "https://developer.download.nvidia.#{repo_domain}/compute/cuda/repos/#{nvidia_platform}/#{arch_suffix}" }
      cached(:repository_key) { platform == 'ubuntu' ? '3bf863cc.pub' : 'D42D0685.pub' }
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['nvidia_repo'])
        stubs_for_resource('nvidia_repo') do |res|
          allow(res).to receive(:repo_domain).and_return(repo_domain)
          allow(res).to receive(:arch_suffix).and_return(arch_suffix)
        end
        ConvergeNvidiaRepo.add(runner)
      end

      it 'adds nvidia repo' do
        is_expected.to add_nvidia_repo('add')
        is_expected.to update_package_repos('update package repos')
        is_expected.to add_package_repos('add nvidia-repo').with(
          repo_name: "nvidia-repo",
          baseurl: repository_url,
          gpgkey: "#{repository_url}/#{repository_key}",
          disable_modularity: true
        )
      end
    end
  end
end

describe 'nvidia_repo:remove' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:repo_domain) { 'repo_domain' }
      cached(:arch_suffix) { 'arch_suffix' }
      cached(:nvidia_platform) do
        case platform
        when 'amazon', 'centos'
          'rhel7'
        when 'redhat'
          "rhel#{version}"
        when 'ubuntu'
          "ubuntu#{version.delete('.')}"
        end
      end
      cached(:repository_url) { "https://developer.download.nvidia.#{repo_domain}/compute/cuda/repos/#{nvidia_platform}/#{arch_suffix}" }
      cached(:repository_key) { platform == 'ubuntu' ? '3bf863cc.pub' : 'D42D0685.pub' }
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['nvidia_repo'])
        stubs_for_resource('nvidia_repo') do |res|
          allow(res).to receive(:repo_domain).and_return(repo_domain)
          allow(res).to receive(:arch_suffix).and_return(arch_suffix)
        end
        ConvergeNvidiaRepo.remove(runner)
      end

      it 'removes nvidia repo' do
        is_expected.to remove_nvidia_repo('remove')
        is_expected.to remove_package_repos('remove nvidia-repo').with_repo_name('nvidia-repo')
      end
    end
  end
end
