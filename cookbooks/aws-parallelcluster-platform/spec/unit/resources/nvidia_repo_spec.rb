require 'spec_helper'

class ConvergeNvidiaRepo
  def self.add(chef_run, driver_version: nil, cuda_version: nil)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      nvidia_repo 'add' do
        driver_version driver_version unless driver_version.nil?
        cuda_version cuda_version unless cuda_version.nil?
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

# Expected local-repo platform identifier for each supported OS.
def nvidia_local_repo_platform_for(platform, version)
  case platform
  when 'amazon' then 'amzn2023'
  when 'ubuntu' then "ubuntu#{version.delete('.')}"
  else "rhel#{version.to_i}"
  end
end

describe 'nvidia_repo helpers' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:driver_version) { '9.8.7' }
      cached(:cuda_version) { '1.2.3' }
      cached(:cuda_suffix) { '4.5.6' }
      cached(:driver_base_url) { 'https://driver.example/nvidia_driver' }
      cached(:cuda_base_url) { 'https://cuda.example/cuda' }
      cached(:sources_dir) { '/fake/sources' }

      cached(:debian?) { platform == 'ubuntu' }
      cached(:local_repo_platform) { nvidia_local_repo_platform_for(platform, version) }
      cached(:arch) { debian? ? 'amd64' : 'x86_64' }
      cached(:driver_pkg_name) { "nvidia-driver-local-repo-#{local_repo_platform}-#{driver_version}" }
      cached(:cuda_pkg_name) { "cuda-repo-#{local_repo_platform}-1-2-local" }
      cached(:driver_pkg_file) do
        debian? ? "#{driver_pkg_name}_1.0-1_#{arch}.deb" : "#{driver_pkg_name}-1.0-1.#{arch}.rpm"
      end
      cached(:cuda_pkg_file) do
        debian? ? "#{cuda_pkg_name}_#{cuda_version}-#{cuda_suffix}-1_#{arch}.deb" : "#{cuda_pkg_name}-#{cuda_version}_#{cuda_suffix}-1.#{arch}.rpm"
      end

      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
        allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
        runner = runner(platform: platform, version: version, step_into: ['nvidia_repo']) do |node|
          node.override['cluster']['nvidia']['driver_version'] = driver_version
          node.override['cluster']['nvidia']['driver_base_url'] = driver_base_url
          node.override['cluster']['nvidia']['cuda']['version'] = cuda_version
          node.override['cluster']['nvidia']['cuda']['base_url'] = cuda_base_url
          node.override['cluster']['nvidia']['cuda']['driver_version_suffix'] = cuda_suffix
          node.override['cluster']['sources_dir'] = sources_dir
        end
        ConvergeNvidiaRepo.add(runner)
      end

      cached(:resource) do
        chef_run.find_resource('nvidia_repo', 'add')
      end

      it 'takes the driver and cuda versions from the attributes' do
        expect(resource.driver_version).to eq(driver_version)
        expect(resource.cuda_version).to eq(cuda_version)
      end

      it 'computes the local repo platform' do
        expect(resource.local_repo_platform).to eq(local_repo_platform)
      end

      it 'computes the driver repo package name, file, path and url' do
        expect(resource.driver_repo_package_name).to eq(driver_pkg_name)
        expect(resource.driver_repo_package_file).to eq(driver_pkg_file)
        expect(resource.driver_repo_package_path).to eq("#{sources_dir}/#{driver_pkg_file}")
        expect(resource.driver_repo_source_url).to eq("#{driver_base_url}/#{driver_pkg_file}")
      end

      it 'computes the cuda repo package name, file, path and url' do
        expect(resource.cuda_repo_package_name).to eq(cuda_pkg_name)
        expect(resource.cuda_repo_package_file).to eq(cuda_pkg_file)
        expect(resource.cuda_repo_package_path).to eq("#{sources_dir}/#{cuda_pkg_file}")
        expect(resource.cuda_repo_source_url).to eq("#{cuda_base_url}/#{cuda_pkg_file}")
      end
    end
  end
end

describe 'nvidia_repo:arch_suffix' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:debian?) { platform == 'ubuntu' }
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
        runner(platform: platform, version: version, step_into: ['nvidia_repo'])
      end
      cached(:resource) do
        ConvergeNvidiaRepo.add(chef_run)
        chef_run.find_resource('nvidia_repo', 'add')
      end

      it 'is the rpm/deb arch on x86' do
        allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
        expect(resource.arch_suffix).to eq(debian? ? 'amd64' : 'x86_64')
      end

      it 'is the rpm/deb arch on arm' do
        allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
        expect(resource.arch_suffix).to eq(debian? ? 'arm64' : 'aarch64')
      end
    end
  end
end

describe 'nvidia_repo:add' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      # Fake versions: tests must not depend on the real versions, they only
      # verify that the versions configured in the attributes are the ones used.
      cached(:driver_version) { '9.8.7' }
      cached(:cuda_version) { '1.2.3' }
      cached(:cuda_suffix) { '4.5.6' }
      cached(:driver_base_url) { 'https://driver.example/nvidia_driver' }
      cached(:cuda_base_url) { 'https://cuda.example/cuda' }
      cached(:sources_dir) { '/fake/sources' }

      cached(:debian?) { platform == 'ubuntu' }
      cached(:local_repo_platform) { nvidia_local_repo_platform_for(platform, version) }
      cached(:arch) { debian? ? 'amd64' : 'x86_64' }
      cached(:driver_pkg_name) { "nvidia-driver-local-repo-#{local_repo_platform}-#{driver_version}" }
      cached(:cuda_pkg_name) { "cuda-repo-#{local_repo_platform}-1-2-local" }
      cached(:driver_pkg_file) do
        debian? ? "#{driver_pkg_name}_1.0-1_#{arch}.deb" : "#{driver_pkg_name}-1.0-1.#{arch}.rpm"
      end
      cached(:cuda_pkg_file) do
        debian? ? "#{cuda_pkg_name}_#{cuda_version}-#{cuda_suffix}-1_#{arch}.deb" : "#{cuda_pkg_name}-#{cuda_version}_#{cuda_suffix}-1.#{arch}.rpm"
      end
      cached(:driver_pkg_path) { "#{sources_dir}/#{driver_pkg_file}" }
      cached(:cuda_pkg_path) { "#{sources_dir}/#{cuda_pkg_file}" }

      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
        allow_any_instance_of(Object).to receive(:on_docker?).and_return(false)
        allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
        mock_file_exists('/usr/bin/nvidia-smi', false)
        mock_file_exists('/usr/local/cuda', false)
        runner = runner(platform: platform, version: version, step_into: ['nvidia_repo']) do |node|
          node.override['cluster']['nvidia']['driver_version'] = driver_version
          node.override['cluster']['nvidia']['driver_base_url'] = driver_base_url
          node.override['cluster']['nvidia']['cuda']['version'] = cuda_version
          node.override['cluster']['nvidia']['cuda']['base_url'] = cuda_base_url
          node.override['cluster']['nvidia']['cuda']['driver_version_suffix'] = cuda_suffix
          node.override['cluster']['sources_dir'] = sources_dir
        end
        ConvergeNvidiaRepo.add(runner)
      end

      it 'downloads the driver and cuda local-repo installers' do
        is_expected.to create_remote_file(driver_pkg_path).with(
          source: "#{driver_base_url}/#{driver_pkg_file}", mode: '0644', retries: 3, retry_delay: 5
        )
        is_expected.to create_remote_file(cuda_pkg_path).with(
          source: "#{cuda_base_url}/#{cuda_pkg_file}", mode: '0644', retries: 3, retry_delay: 5
        )
      end

      if platform == 'ubuntu'
        it 'installs the local-repo debs, enrolls keys and refreshes apt once' do
          is_expected.to install_dpkg_package(driver_pkg_name).with(source: driver_pkg_path)
          is_expected.to install_dpkg_package(cuda_pkg_name).with(source: cuda_pkg_path)
          is_expected.to run_execute("Install keyring for #{driver_pkg_name}")
          is_expected.to run_execute("Install keyring for #{cuda_pkg_name}")
          is_expected.to update_apt_update('Update apt cache for NVIDIA local repos')
        end

        it 'refreshes the apt cache only once for all local repos' do
          apt_updates = chef_run.run_context.resource_collection.select do |r|
            r.resource_name == :apt_update
          end
          expect(apt_updates.size).to eq(1)
        end
      else
        it 'installs the local-repo rpms and refreshes the dnf cache once' do
          is_expected.to install_rpm_package(driver_pkg_name).with(source: driver_pkg_path)
          is_expected.to install_rpm_package(cuda_pkg_name).with(source: cuda_pkg_path)
          is_expected.to run_execute('Refresh dnf metadata for NVIDIA local repos').with(command: 'dnf clean all')
          is_expected.to flush_cache_dnf_package('Update dnf cache for NVIDIA local repos')
        end

        it 'runs dnf clean all only once for all local repos' do
          clean_alls = chef_run.run_context.resource_collection.select do |r|
            r.resource_name == :execute && r.name == 'Refresh dnf metadata for NVIDIA local repos'
          end
          expect(clean_alls.size).to eq(1)
        end
      end
    end
  end
end

describe 'nvidia_repo:add skip conditions' do
  # Fake version: tests must not depend on the real version, they only verify
  # that the version configured in the attribute is the one being used.
  def converge_add(nvidia_enabled:, on_docker:, nvidia_smi:, cuda:)
    allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(nvidia_enabled)
    allow_any_instance_of(Object).to receive(:on_docker?).and_return(on_docker)
    allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
    mock_file_exists('/usr/bin/nvidia-smi', nvidia_smi)
    mock_file_exists('/usr/local/cuda', cuda)
    runner = runner(platform: 'amazon', version: '2023', step_into: ['nvidia_repo']) do |node|
      node.override['cluster']['nvidia']['cuda']['version'] = '1.2.3'
    end
    ConvergeNvidiaRepo.add(runner)
  end

  context 'when nvidia is not enabled' do
    cached(:converged) { converge_add(nvidia_enabled: false, on_docker: false, nvidia_smi: false, cuda: false) }

    it 'does not add any repo' do
      expect(converged).not_to install_rpm_package(/nvidia-driver-local-repo/)
      expect(converged).not_to install_rpm_package(/cuda-repo/)
    end
  end

  context 'when on docker' do
    cached(:converged) { converge_add(nvidia_enabled: true, on_docker: true, nvidia_smi: false, cuda: false) }

    it 'does not add any repo' do
      expect(converged).not_to install_rpm_package(/nvidia-driver-local-repo/)
      expect(converged).not_to install_rpm_package(/cuda-repo/)
    end
  end

  context 'when the driver is already installed but cuda is not' do
    cached(:converged) { converge_add(nvidia_enabled: true, on_docker: false, nvidia_smi: true, cuda: false) }

    it 'skips the driver repo but still adds the cuda repo' do
      expect(converged).not_to install_rpm_package(/nvidia-driver-local-repo/)
      expect(converged).to install_rpm_package(/cuda-repo-amzn2023-1-2-local/)
    end
  end

  context 'when cuda is already installed but the driver is not' do
    cached(:converged) { converge_add(nvidia_enabled: true, on_docker: false, nvidia_smi: false, cuda: true) }

    it 'skips the cuda repo but still adds the driver repo' do
      expect(converged).to install_rpm_package(/nvidia-driver-local-repo/)
      expect(converged).not_to install_rpm_package(/cuda-repo-amzn2023-1-2-local/)
    end
  end
end

describe 'nvidia_repo: overriding base_url to the official NVIDIA URLs' do
  # Fake versions: tests must not depend on the real versions, they only
  # verify that the versions configured in the attributes are the ones used.
  cached(:driver_version) { '9.8.7' }
  cached(:cuda_version) { '1.2.3' }
  cached(:cuda_suffix) { '4.5.6' }
  cached(:driver_base_url) { "https://developer.download.nvidia.com/compute/nvidia-driver/#{driver_version}/local_installers" }
  cached(:cuda_base_url) { "https://developer.download.nvidia.com/compute/cuda/#{cuda_version}/local_installers" }
  cached(:driver_pkg_file) { "nvidia-driver-local-repo-amzn2023-#{driver_version}-1.0-1.x86_64.rpm" }
  cached(:cuda_pkg_file) { "cuda-repo-amzn2023-1-2-local-#{cuda_version}_#{cuda_suffix}-1.x86_64.rpm" }

  cached(:chef_run) do
    allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
    allow_any_instance_of(Object).to receive(:on_docker?).and_return(false)
    allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
    mock_file_exists('/usr/bin/nvidia-smi', false)
    mock_file_exists('/usr/local/cuda', false)
    runner = runner(platform: 'amazon', version: '2023', step_into: ['nvidia_repo']) do |node|
      node.override['cluster']['nvidia']['driver_version'] = driver_version
      node.override['cluster']['nvidia']['driver_base_url'] = driver_base_url
      node.override['cluster']['nvidia']['cuda']['version'] = cuda_version
      node.override['cluster']['nvidia']['cuda']['base_url'] = cuda_base_url
      node.override['cluster']['nvidia']['cuda']['driver_version_suffix'] = cuda_suffix
    end
    ConvergeNvidiaRepo.add(runner)
  end

  it 'downloads the driver local repo from the official NVIDIA URL' do
    is_expected.to create_remote_file(%r{/#{driver_pkg_file}$}).with(
      source: "#{driver_base_url}/#{driver_pkg_file}"
    )
  end

  it 'downloads the cuda local repo from the official NVIDIA URL' do
    is_expected.to create_remote_file(%r{/#{cuda_pkg_file}$}).with(
      source: "#{cuda_base_url}/#{cuda_pkg_file}"
    )
  end
end

describe 'nvidia_repo:remove' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      # Fake versions: tests must not depend on the real versions, they only
      # verify that the versions configured in the attributes are the ones used.
      cached(:driver_version) { '9.8.7' }
      cached(:cuda_version) { '1.2.3' }
      cached(:cuda_suffix) { '4.5.6' }
      cached(:sources_dir) { '/fake/sources' }
      cached(:debian?) { platform == 'ubuntu' }
      cached(:local_repo_platform) { nvidia_local_repo_platform_for(platform, version) }
      cached(:arch) { debian? ? 'amd64' : 'x86_64' }
      cached(:driver_pkg_name) { "nvidia-driver-local-repo-#{local_repo_platform}-#{driver_version}" }
      cached(:cuda_pkg_name) { "cuda-repo-#{local_repo_platform}-1-2-local" }
      cached(:driver_pkg_file) do
        debian? ? "#{driver_pkg_name}_1.0-1_#{arch}.deb" : "#{driver_pkg_name}-1.0-1.#{arch}.rpm"
      end
      cached(:cuda_pkg_file) do
        debian? ? "#{cuda_pkg_name}_#{cuda_version}-#{cuda_suffix}-1_#{arch}.deb" : "#{cuda_pkg_name}-#{cuda_version}_#{cuda_suffix}-1.#{arch}.rpm"
      end

      context 'when this run added the repos' do
        cached(:chef_run) do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          runner = runner(platform: platform, version: version, step_into: ['nvidia_repo']) do |node|
            node.override['cluster']['nvidia']['driver_version'] = driver_version
            node.override['cluster']['nvidia']['cuda']['version'] = cuda_version
            node.override['cluster']['nvidia']['cuda']['driver_version_suffix'] = cuda_suffix
            node.override['cluster']['sources_dir'] = sources_dir
          end
          runner.node.run_state['nvidia_driver_repo_added'] = true
          runner.node.run_state['nvidia_cuda_repo_added'] = true
          ConvergeNvidiaRepo.remove(runner)
        end

        it 'removes the local-repo packages and deletes the installers' do
          if debian?
            is_expected.to purge_package(driver_pkg_name)
            is_expected.to purge_package(cuda_pkg_name)
          else
            is_expected.to remove_package(driver_pkg_name)
            is_expected.to remove_package(cuda_pkg_name)
          end
          is_expected.to delete_file("#{sources_dir}/#{driver_pkg_file}")
          is_expected.to delete_file("#{sources_dir}/#{cuda_pkg_file}")
        end

        it 'refreshes the package manager metadata after removal' do
          if debian?
            is_expected.to update_apt_update('Refresh apt metadata after removing NVIDIA local repos')
          else
            is_expected.to run_execute('Refresh dnf metadata after removing NVIDIA local repos').with(
              command: 'dnf clean all'
            )
          end
        end

        it 'refreshes the package manager metadata after each repo removal' do
          ordered_names = chef_run.run_context.resource_collection.map(&:name)
          refresh_name = if debian?
                           'Refresh apt metadata after removing NVIDIA local repos'
                         else
                           'Refresh dnf metadata after removing NVIDIA local repos'
                         end

          driver_remove_index = ordered_names.index(driver_pkg_name)
          cuda_remove_index = ordered_names.index(cuda_pkg_name)
          refresh_indexes = ordered_names.each_index.select { |i| ordered_names[i] == refresh_name }

          expect(driver_remove_index).not_to be_nil
          expect(cuda_remove_index).not_to be_nil
          # One refresh per removed repo, and each refresh comes after a removal.
          expect(refresh_indexes.size).to eq(2)
          expect(refresh_indexes.any? { |i| i > driver_remove_index }).to be(true)
          expect(refresh_indexes.any? { |i| i > cuda_remove_index }).to be(true)
        end
      end

      context 'when this run added only the driver repo' do
        cached(:chef_run) do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          runner = runner(platform: platform, version: version, step_into: ['nvidia_repo']) do |node|
            node.override['cluster']['nvidia']['driver_version'] = driver_version
            node.override['cluster']['nvidia']['cuda']['version'] = cuda_version
            node.override['cluster']['nvidia']['cuda']['driver_version_suffix'] = cuda_suffix
            node.override['cluster']['sources_dir'] = sources_dir
          end
          runner.node.run_state['nvidia_driver_repo_added'] = true
          ConvergeNvidiaRepo.remove(runner)
        end

        it 'removes only the driver repo, leaving the cuda repo untouched' do
          if debian?
            is_expected.to purge_package(driver_pkg_name)
            is_expected.not_to purge_package(cuda_pkg_name)
          else
            is_expected.to remove_package(driver_pkg_name)
            is_expected.not_to remove_package(cuda_pkg_name)
          end
        end

        it 'still refreshes the package manager metadata after removing the driver repo' do
          if debian?
            is_expected.to update_apt_update('Refresh apt metadata after removing NVIDIA local repos')
          else
            is_expected.to run_execute('Refresh dnf metadata after removing NVIDIA local repos').with(
              command: 'dnf clean all'
            )
          end
        end
      end

      context 'when this run did not add the repos' do
        cached(:chef_run) do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          runner = runner(platform: platform, version: version, step_into: ['nvidia_repo']) do |node|
            node.override['cluster']['nvidia']['driver_version'] = driver_version
            node.override['cluster']['nvidia']['cuda']['version'] = cuda_version
            node.override['cluster']['nvidia']['cuda']['driver_version_suffix'] = cuda_suffix
          end
          ConvergeNvidiaRepo.remove(runner)
        end

        it 'removes nothing' do
          is_expected.not_to remove_package(driver_pkg_name)
          is_expected.not_to remove_package(cuda_pkg_name)
          is_expected.not_to purge_package(driver_pkg_name)
          is_expected.not_to purge_package(cuda_pkg_name)
        end

        it 'does not refresh the package manager metadata' do
          is_expected.not_to update_apt_update('Refresh apt metadata after removing NVIDIA local repos')
          is_expected.not_to run_execute('Refresh dnf metadata after removing NVIDIA local repos')
        end
      end
    end
  end
end
