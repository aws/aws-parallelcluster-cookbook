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
        cached(:package_source_version) { '8.0.31' }
        cached(:package_version) { '8.0.31-1' }
        cached(:package_filename) { "mysql-community-client-#{package_version}.tar.gz" }
        cached(:s3_url) { 's3://url' }
        cached(:package_platform) do
          platform_version = if version.to_i == 2
                               7
                             else
                               version.to_i
                             end
          if architecture == 'aarch64'
            "el/#{platform_version}/aarch64"
          elsif architecture == 'x86_64'
            if platform == 'ubuntu'
              "ubuntu/${version}/x86_64"
            else
              "el/#{platform_version}/x86_64"
            end
          else
            pending "unsupported architecture #{architecture}"
          end
        end
        cached(:package_archive) { "#{s3_url}/mysql/#{package_platform}/#{package_filename}" }
        cached(:tarfile) { "/tmp/mysql-community-client-#{package_version}.tar.gz" }
        cached(:repository_packages) do
          if platform == 'ubuntu'
            if version.to_i == 18
              %w(libmysqlclient-dev libmysqlclient20)
            elsif version.to_i >= 20
              %w(libmysqlclient-dev libmysqlclient21)
            end
          else
            %w(mysql-community-devel mysql-community-libs mysql-community-common mysql-community-client-plugins mysql-community-libs-compat)
          end
        end
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['mysql_client']) do |node|
            node.automatic['kernel']['machine'] = architecture
            node.override['cluster']['sources_dir'] = source_dir
            node.override['cluster']['artifacts_s3_url'] = s3_url
          end
          ConvergeMysqlClient.setup(runner)
        end
        cached(:node) { chef_run.node }

        it 'sets up mysql client' do
          is_expected.to setup_mysql_client('setup')
        end

        if %w(amazon centos redhat).include?(platform)
          it 'logs MySQL archive URL' do
            is_expected.to write_log("Downloading MySQL packages archive from #{package_archive}")
          end

          it 'downloads and installs packages' do
            is_expected.to create_if_missing_remote_file(tarfile)
              .with(source: package_archive)
              .with(mode: '0644')
              .with(retries: 3)
              .with(retry_delay: 5)

            is_expected.to run_bash('Install MySQL packages')
              .with(user: 'root')
              .with(group: 'root')
              .with(cwd: '/tmp')
              .with(code: %{        set -e

        EXTRACT_DIR=$(mktemp -d --tmpdir mysql.XXXXXXX)
        tar xf "#{tarfile}" --directory "${EXTRACT_DIR}"
        yum install -y ${EXTRACT_DIR}/*
})
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

#{"#{s3_url}/source/mysql-#{package_source_version}.tar.gz"}
))
            .with(owner: 'root')
            .with(group: 'root')
            .with(mode: '0644')
        end
      end
    end
  end
end
