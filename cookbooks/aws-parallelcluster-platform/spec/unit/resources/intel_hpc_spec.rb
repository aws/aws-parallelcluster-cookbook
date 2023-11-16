require 'spec_helper'

class ConvergeIntelHpc
  def self.setup(chef_run, deps:)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      intel_hpc 'setup' do
        dependencies deps
        action :setup
      end
    end
  end

  def self.configure(chef_run, deps:)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      intel_hpc 'configure' do
        dependencies deps
        action :configure
      end
    end
  end
end

describe 'intel_hpc:setup' do
  cached(:sources_dir) { 'sources_test_dir' }
  cached(:dependencies) { %w(dep1 dep2) }

  cached(:chef_run) do
    runner = runner(platform: 'centos', version: '7', step_into: ['intel_hpc']) do |node|
      node.override['cluster']['sources_dir'] = sources_dir
      node.override['cluster']['region'] = aws_region
    end
    ConvergeIntelHpc.setup(runner, deps: dependencies)
  end
  cached(:node) { chef_run.node }

  it 'sets up intel_hpc' do
    is_expected.to setup_intel_hpc('setup')
  end

  it 'saves properties for InSpec tests' do
    expect(node['cluster']['intelhpc']['dependencies']).to eq(dependencies)
    is_expected.to write_node_attributes 'Save properties for InSpec tests'
  end

  it 'creates sources directory' do
    is_expected.to create_directory(sources_dir).with_recursive(true)
  end

  it 'downloads dependencies' do
    expected_command = /yum install --downloadonly #{dependencies.join(' ')} --downloaddir=#{sources_dir}/
    is_expected.to run_bash('download dependencies Intel HPC platform')
    expect(chef_run.bash('download dependencies Intel HPC platform').code).to match(expected_command)
  end
end

describe 'intel_hpc:configure' do
  cached(:aws_region) { 'test_region' }
  cached(:sources_dir) { 'sources_test_dir' }
  cached(:modulefile_dir) { '/usr/share/Modules/modulefiles' }
  cached(:intel_hpc_spec_rpms_dir) { '/opt/intel/rpms' }
  cached(:psxe_version) { '2020.4-17' }
  cached(:dependencies) { %w(dep1 dep2) }

  cached(:chef_run) do
    runner = runner(platform: 'centos', version: '7', step_into: ['intel_hpc']) do |node|
      node.override['cluster']['sources_dir'] = sources_dir
      node.override['cluster']['region'] = aws_region
      node.override['cluster']['enable_intel_hpc_platform'] = 'true'
    end
    allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
    ConvergeIntelHpc.configure(runner, deps: dependencies)
  end
  cached(:node) { chef_run.node }

  it 'configures intel_hpc' do
    is_expected.to configure_intel_hpc('configure')
  end

  it 'saves properties for InSpec tests' do
    is_expected.to write_node_attributes 'Save properties for InSpec tests'
  end

  it 'installs non-intel dependencies first' do
    is_expected.to run_bash('install non-intel dependencies').with_cwd(sources_dir)
    expect(chef_run.bash('install non-intel dependencies').code)
      .to match(/yum localinstall --cacheonly -y `ls #{dependencies.map { |d| "#{d}\\*.rpm" }.join(' ')}`/)
  end

  it 'installs intel hpc platform' do
    is_expected.to run_bash('install intel hpc platform')
      .with_cwd(sources_dir)
      .with_creates('/etc/intel-hpc-platform-release')
    expect(chef_run.bash('install intel hpc platform').code)
      .to match(/yum localinstall --cacheonly -y #{intel_hpc_spec_rpms_dir}/)
  end

  it 'creates intelpython module directory' do
    is_expected.to create_directory("#{modulefile_dir}/intelpython")
  end

  it 'creates intelpython2_modulefile' do
    is_expected.to create_cookbook_file('intelpython2_modulefile').with(
      source: 'intel/intelpython2_modulefile',
      path: "#{modulefile_dir}/intelpython/2",
      user: 'root',
      group: 'root',
      mode: '0755'
    )
  end

  it 'creates intelpython3_modulefile' do
    is_expected.to create_cookbook_file('intelpython3_modulefile').with(
      source: 'intel/intelpython3_modulefile',
      path: "#{modulefile_dir}/intelpython/3",
      user: 'root',
      group: 'root',
      mode: '0755'
    )
  end

  it 'creates modulefile intelmkl for Intel optimized math kernel library' do
    is_expected.to run_create_modulefile("#{modulefile_dir}/intelmkl").with(
      source_path: "/opt/intel/psxe_runtime/linux/mkl/bin/mklvars.sh",
      modulefile: psxe_version
    )
  end

  it 'creates modulefile intelpsxe' do
    is_expected.to run_create_modulefile("#{modulefile_dir}/intelpsxe").with(
      source_path: "/opt/intel/psxe_runtime/linux/bin/psxevars.sh",
      modulefile: psxe_version
    )
  end
end

describe 'intel_hpc:configure on HeadNode' do
  cached(:aws_region) { 'test_region' }
  cached(:aws_domain) { 'test_domain' }
  cached(:sources_dir) { 'sources_test_dir' }
  cached(:modulefile_dir) { '/usr/share/Modules/modulefiles' }
  cached(:intel_hpc_spec_rpms_dir) { '/opt/intel/rpms' }
  cached(:psxe_version) { '2020.4-17' }
  cached(:intel_psxe_rpms_dir) { "#{sources_dir}/intel/psxe" }
  cached(:packages) do
    %w(intel-hpc-platform-core-intel-runtime-advisory intel-hpc-platform-compat-hpc-advisory
                                intel-hpc-platform-core intel-hpc-platform-core-advisory intel-hpc-platform-hpc-cluster
                                intel-hpc-platform-compat-hpc intel-hpc-platform-core-intel-runtime)
  end

  cached(:psxe_noarch_packages) do
    %w(intel-tbb-common-runtime intel-mkl-common-runtime intel-psxe-common-runtime
                               intel-ipp-common-runtime intel-ifort-common-runtime intel-icc-common-runtime
                               intel-daal-common-runtime intel-comp-common-runtime)
  end

  cached(:psxe_i486_dependencies) do
    %w(intel-tbb-runtime intel-tbb-libs-runtime intel-comp-runtime
                              intel-daal-runtime intel-icc-runtime intel-ifort-runtime
                              intel-ipp-runtime intel-mkl-runtime intel-openmp-runtime)
  end

  cached(:platform_name) { 'el7' }
  cached(:version) { '2018.0-7' }
  cached(:s3_base_url) { "https://#{aws_region}-aws-parallelcluster.s3.#{aws_region}.#{aws_domain}" }
  cached(:intel_hpc_packages_dir_s3_url) { "#{s3_base_url}/archives/IntelHPC/#{platform_name}" }
  cached(:dependencies) { %w(dep1 dep2) }

  cached(:chef_run) do
    runner = runner(platform: 'centos', version: '7', step_into: ['intel_hpc']) do |node|
      node.override['cluster']['sources_dir'] = sources_dir
      node.override['cluster']['region'] = aws_region
      node.override['cluster']['enable_intel_hpc_platform'] = 'true'
      node.override['cluster']['node_type'] = 'HeadNode'
    end
    allow_any_instance_of(Object).to receive(:aws_domain).and_return(aws_domain)
    allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
    ConvergeIntelHpc.configure(runner, deps: dependencies)
  end

  it 'configures intel_hpc' do
    is_expected.to configure_intel_hpc('configure')
  end

  it 'creates intel rpms dir' do
    is_expected.to create_directory(intel_hpc_spec_rpms_dir).with_recursive(true)
  end

  it "downloads packages from s3" do
    packages.each do |package_name|
      package_basename = "#{package_name}-#{version}.#{platform_name}.x86_64.rpm"
      is_expected.to create_if_missing_remote_file("#{intel_hpc_spec_rpms_dir}/#{package_basename}").with(
        source: "#{intel_hpc_packages_dir_s3_url}/hpc_platform_spec/#{package_basename}",
        mode: '0744',
        retries: 3,
        retry_delay: 5
      )
    end
  end

  it 'creates intel psxe rpms dir' do
    is_expected.to create_directory("#{sources_dir}/intel/psxe").with_recursive(true)
  end

  it "download psxe noarch packages" do
    psxe_noarch_packages.each do |psxe_noarch_package|
      package_basename = "#{psxe_noarch_package}-#{psxe_version}.noarch.rpm"
      is_expected.to create_if_missing_remote_file("#{intel_psxe_rpms_dir}/#{package_basename}").with(
        source: "#{intel_hpc_packages_dir_s3_url}/psxe/#{package_basename}",
        mode: '0744',
        retries: 3,
        retry_delay: 5
      )
    end
  end

  it 'downloads PSXE main runtime package for 32-bit Intel compatible processors' do
    intel_architecture = 'i486'
    package_basename = "intel-psxe-runtime-#{psxe_version}.#{intel_architecture}.rpm"
    is_expected.to create_if_missing_remote_file("#{intel_psxe_rpms_dir}/#{package_basename}").with(
      source: "#{intel_hpc_packages_dir_s3_url}/psxe/#{package_basename}",
      mode: '0744',
      retries: 3,
      retry_delay: 5
    )
  end

  it 'downloads PSXE main runtime package for 64-bit Intel compatible processors' do
    intel_architecture = 'x86_64'
    package_basename = "intel-psxe-runtime-#{psxe_version}.#{intel_architecture}.rpm"
    is_expected.to create_if_missing_remote_file("#{intel_psxe_rpms_dir}/#{package_basename}").with(
      source: "#{intel_hpc_packages_dir_s3_url}/psxe/#{package_basename}",
      mode: '0744',
      retries: 3,
      retry_delay: 5
    )
  end

  it 'downloads PSXE dependencies for 32-bit Intel compatible processors' do
    intel_architecture = 'i486'
    num_bits_for_arch = '32'
    psxe_i486_dependencies.each do |psxe_archful_package|
      package_basename = "#{psxe_archful_package}-#{num_bits_for_arch}bit-#{psxe_version}.#{intel_architecture}.rpm"
      is_expected.to create_if_missing_remote_file("#{intel_psxe_rpms_dir}/#{package_basename}").with(
        source: "#{intel_hpc_packages_dir_s3_url}/psxe/#{package_basename}",
        mode: '0744',
        retries: 3,
        retry_delay: 5
      )
    end
  end

  it 'downloads PSXE dependencies for 64-bit Intel compatible processors' do
    intel_architecture = 'x86_64'
    num_bits_for_arch = '64'
    (psxe_i486_dependencies + %w(intel-mpi-runtime)).each do |psxe_archful_package|
      package_basename = "#{psxe_archful_package}-#{num_bits_for_arch}bit-#{psxe_version}.#{intel_architecture}.rpm"
      is_expected.to create_if_missing_remote_file("#{intel_psxe_rpms_dir}/#{package_basename}").with(
        source: "#{intel_hpc_packages_dir_s3_url}/psxe/#{package_basename}",
        mode: '0744',
        retries: 3,
        retry_delay: 5
      )
    end
  end

  it 'installs all downloaded PSXE packages' do
    is_expected.to run_bash('install PSXE packages').with_cwd(sources_dir)
    expect(chef_run.bash('install PSXE packages').code)
      .to match(%r{yum localinstall --cacheonly -y #{intel_psxe_rpms_dir}/\*})
  end

  it 'installs intel-optimized version of python 2' do
    python_version = '2'
    package_version = '2019.4-088'
    package_basename = "intelpython#{python_version}-#{package_version}.x86_64.rpm"
    dest_path = "#{sources_dir}/#{package_basename}"
    is_expected.to create_if_missing_remote_file(dest_path).with(
      source: "#{intel_hpc_packages_dir_s3_url}/intelpython#{python_version}/#{package_basename}",
      mode: '0744',
      retries: 3,
      retry_delay: 5
    )

    is_expected.to run_bash("install intelpython#{python_version}").with_cwd(sources_dir)
    expect(chef_run.bash("install intelpython#{python_version}").code)
      .to match(/yum localinstall --cacheonly -y #{dest_path}/)
  end

  it 'installs intel-optimized version of python 3' do
    python_version = '3'
    package_version = '2020.2-902'
    package_basename = "intelpython#{python_version}-#{package_version}.x86_64.rpm"
    dest_path = "#{sources_dir}/#{package_basename}"
    is_expected.to create_if_missing_remote_file(dest_path).with(
      source: "#{intel_hpc_packages_dir_s3_url}/intelpython#{python_version}/#{package_basename}",
      mode: '0744',
      retries: 3,
      retry_delay: 5
    )

    is_expected.to run_bash("install intelpython#{python_version}").with_cwd(sources_dir)
    expect(chef_run.bash("install intelpython#{python_version}").code)
      .to match(/yum localinstall --cacheonly -y #{dest_path}/)
  end
end
