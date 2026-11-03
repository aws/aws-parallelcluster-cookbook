require 'spec_helper'

class ConvergePypiDependencies
  def self.download(chef_run, dependency_type, destination)
    chef_run.converge_dsl('aws-parallelcluster-shared') do
      pypi_dependencies dependency_type do
        destination destination
      end
    end
  end
end

describe 'pypi_dependencies' do
  cached(:destination) { '/opt/parallelcluster/cookbook-dependencies.tgz' }
  cached(:package_file) { 'x86_64/pypi-cookbook-dependencies-3.14-x86_64.tgz' }
  cached(:region) { 'eu-west-1' }
  cached(:artifacts_s3_url) { 'https://eu-west-1-bucket.example.com/archives' }

  def build_runner(base_url)
    ChefSpec::SoloRunner.new(step_into: ['pypi_dependencies']) do |node|
      node.override['cluster']['region'] = region
      node.override['cluster']['python-major-minor-version'] = '3.14'
      node.override['kernel']['machine'] = 'x86_64'
      node.override['cluster']['artifacts_s3_url'] = artifacts_s3_url
      node.override['cluster']['pypi_dependencies_base_url'] = base_url unless base_url.nil?
    end
  end

  context 'with the default per-release base URL' do
    cached(:chef_run) do
      runner = build_runner(nil)
      runner.node.override['cluster']['parallelcluster-version'] = '3.16.3'
      ConvergePypiDependencies.download(runner, 'cookbook', destination)
    end

    it 'downloads the per-release bundle, without falling back to other bundles' do
      is_expected.to create_if_missing_remote_file(destination).with(
        source: ["#{artifacts_s3_url}/dependencies/PyPi/3.16.3/#{package_file}"],
        mode: '0644',
        retries: 3,
        retry_delay: 5
      )
    end

    it 'does not use the AWS CLI' do
      is_expected.not_to run_execute(/^download cookbook dependencies from/)
    end
  end

  context 'with an S3 base URL' do
    cached(:base_url) { 's3://jenkins-bucket/pypi-dependencies/cookbook-ref-node-ref' }
    cached(:chef_run) do
      ConvergePypiDependencies.download(build_runner(base_url), 'cookbook', destination)
    end

    it 'downloads the bundle with the AWS CLI' do
      is_expected.to run_execute("download cookbook dependencies from #{base_url}").with(
        command: "/usr/local/bin/aws s3 cp --region #{region} #{base_url}/#{package_file} #{destination}",
        retries: 3,
        retry_delay: 5,
        creates: destination
      )
    end

    it 'does not use remote_file' do
      is_expected.not_to create_if_missing_remote_file(destination)
    end
  end
end
