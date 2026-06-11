require 'spec_helper'

class ConvergeMysqlClient
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-slurm') do
      mysql_client 'setup' do
        action :setup
      end
    end
  end

  def self.validate(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-slurm') do
      mysql_client 'validate' do
        action :validate
      end
    end
  end
end

describe 'mysql_client:setup' do
  for_all_oses do |platform, version|
    %w(x86_64 aarch64).each do |architecture|
      context "on #{platform}#{version} #{architecture}" do
        cached(:source_dir) { 'SOURCE_DIR' }
        cached(:package_source_version) { 'VERSION' }
        cached(:package_version) { 'VERSION-1' }
        cached(:s3_url) { 's3://url' }
        cached(:mysql_base_url) { "#{s3_url}/mysql" }
        cached(:el_version) do
          if platform == 'amazon' && version == '2023'
            9
          else
            version.to_i
          end
        end
        cached(:package_platform) { "el/#{el_version}/#{architecture}" }
        cached(:package_base_url) { "#{mysql_base_url}/#{package_platform}" }
        cached(:mysql_rpm_filenames) do
          components = %w(common client-plugins libs devel)
          components.map { |c| "mysql-community-#{c}-#{package_version}.el#{el_version}.#{architecture}.rpm" }
        end
        # Ubuntu installs from the apt repository by package name; RHEL-based
        # platforms install the downloaded RPMs directly (see mysql_rpm_filenames).
        cached(:repository_packages) do
          if version.to_i == 18
            %w(libmysqlclient-dev libmysqlclient20)
          elsif version.to_i >= 20
            %w(libmysqlclient-dev libmysqlclient21)
          end
        end
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['mysql_client']) do |node|
            node.automatic['kernel']['machine'] = architecture
            node.override['cluster']['sources_dir'] = source_dir
            node.override['cluster']['artifacts_s3_url'] = s3_url
            node.override['cluster']['mysql']['version'] = package_version
            node.override['cluster']['mysql']['source_version'] = package_source_version
            node.override['cluster']['mysql']['base_url'] = mysql_base_url
          end
          ConvergeMysqlClient.setup(runner)
        end
        cached(:node) { chef_run.node }

        it 'sets up mysql client' do
          is_expected.to setup_mysql_client('setup')
        end

        if %w(amazon centos redhat rocky).include?(platform)
          it 'downloads each MySQL RPM and installs them in one transaction' do
            mysql_rpm_filenames.each do |rpm|
              is_expected.to create_if_missing_remote_file("/tmp/#{rpm}")
                .with(source: "#{package_base_url}/#{rpm}")
                .with(mode: '0644')
                .with(retries: 3)
                .with(retry_delay: 5)
            end

            is_expected.to run_bash('Install MySQL packages')
              .with(user: 'root')
              .with(group: 'root')
              .with(cwd: '/tmp')
              .with(code: %(        set -e
        yum install -y #{mysql_rpm_filenames.join(' ')}
))
          end

        elsif platform == 'ubuntu'
          it 'installs package from apt repository' do
            is_expected.to periodic_apt_update('')
            is_expected.to install_package(repository_packages)
              .with(retries: 3)
              .with(retry_delay: 5)
          end
        else
          pending "Implement for #{platform}"
        end

        it 'creates sources directory' do
          is_expected.to create_directory(source_dir)
        end

        it 'creates source link' do
          is_expected.to create_file("#{source_dir}/mysql_source_code.txt")
            .with(content: %(You can get MySQL source code here:

#{"#{mysql_base_url}/source/mysql-#{package_source_version}.tar.gz"}
))
            .with(owner: 'root')
            .with(group: 'root')
            .with(mode: '0644')
        end
      end
    end
  end
end
