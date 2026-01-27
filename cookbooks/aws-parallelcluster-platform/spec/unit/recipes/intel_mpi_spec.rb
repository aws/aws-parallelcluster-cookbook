require 'spec_helper'

describe 'aws-parallelcluster-platform::intel_mpi' do
  cached(:source_dir) { 'source_dir_for_tests' }
  cached(:aws_region) { 'region_for_tests' }
  cached(:intelmpi_version) { 'VERSION' }
  cached(:intelmpi_full_version) { 'VERSION.0' }
  cached(:intelmpi_base_url) { "https://#{aws_region}-aws-parallelcluster.s3.#{aws_region}.test_aws_domain/archives/impi" }
  cached(:chef_run) do
    runner = ChefSpec::Runner.new do |node|
      node.override['cluster']['sources_dir'] = source_dir
      node.override['cluster']['region'] = aws_region
      node.override['cluster']['intelmpi']['version'] = intelmpi_version
      node.override['cluster']['intelmpi']['full_version'] = intelmpi_full_version
      node.override['cluster']['intelmpi']['base_url'] = intelmpi_base_url
    end
    runner.converge(described_recipe)
  end

  it 'sets up intel mpi' do
    is_expected.to write_node_attributes('dump node attributes')
  end

  it 'installs modules' do
    is_expected.to setup_modules('Prerequisite: Environment modules')
  end

  it 'fetches intel mpi installer script' do
    is_expected.to create_remote_file("#{source_dir}/intel-mpi-#{intelmpi_full_version}_offline.sh").with(
      source: "#{intelmpi_base_url}/intel-mpi-#{intelmpi_full_version}_offline.sh",
      mode: '0744',
      retries: 3,
      retry_delay: 5
    )
  end

  it 'installs intel mpi' do
    is_expected.to run_bash('install intel mpi').with(
      cwd: source_dir,
      creates: "/opt/intel/mpi/#{intelmpi_version}"
    ).with_code(/chmod \+x intel-mpi-#{intelmpi_full_version}_offline.sh/)
                                                .with_code(%r{--remove-extracted-files yes -a --silent --eula accept --install-dir /opt/intel})
                                                .with_code(/rm -f intel-mpi-#{intelmpi_full_version}_offline.sh/)
  end

  it 'appends intel module file dir to modules config' do
    is_expected.to append_to_config_modules('append intel modules file dir to modules conf')
      .with_line("/opt/intel/mpi/#{intelmpi_version}/etc/modulefiles/")
  end

  it 'renames intel mpi module' do
    is_expected.to run_execute('rename intel mpi modules file name').with(
      command: "mv /opt/intel/mpi/#{intelmpi_version}/etc/modulefiles/mpi /opt/intel/mpi/#{intelmpi_version}/etc/modulefiles/intelmpi",
      creates: "/opt/intel/mpi/#{intelmpi_version}/etc/modulefiles/intelmpi"
    )
  end

  it 'adds Qt source file' do
    is_expected.to create_template("/opt/intel/mpi/#{intelmpi_version}/qt_source_code.txt").with(
      source: 'intel_mpi/qt_source_code.erb',
      owner: 'root',
      group: 'root',
      mode: '0644',
      variables: {
        aws_region: aws_region,
        aws_domain: 'test_aws_domain',
        intelmpi_qt_version: '6.5.3',
      }
    )
  end
end
