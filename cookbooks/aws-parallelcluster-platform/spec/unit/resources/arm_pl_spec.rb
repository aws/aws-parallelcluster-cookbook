require 'spec_helper'

class ConvergeArmPl
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      arm_pl 'setup' do
        action :setup
      end
    end
  end
end

describe 'arm_pl:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version} x86" do
      cached(:aws_region) { 'test_region' }
      cached(:aws_domain) { 'test_domain' }
      cached(:armpl_major_minor_version) do
        'armpl_test_version'
      end

      cached(:armpl_platform) do
        case platform
        when 'centos'
          'RHEL-7'
        when 'ubuntu'
          "Ubuntu-#{version}"
        when 'amazon'
          if version == '2023'
            'RHEL-9'
          end
        else
          "RHEL-#{version}"
        end
      end

      cached(:gcc_major_minor_version) do
        case "#{platform}#{version}"
        when 'amazon2023', 'ubuntu24.04', 'ubuntu22.04', 'redhat9', 'rocky9'
          '11.3'
        else
          '9.3'
        end
      end

      cached(:gcc_patch_version) { '0' }
      cached(:sources_dir) { 'sources_test_dir' }
      cached(:modulefile_dir) { platform == 'ubuntu' ? '/usr/share/modules/modulefiles' : '/usr/share/Modules/modulefiles' }
      cached(:package_manager) { platform == 'ubuntu' ? 'deb' : 'rpm' }
      cached(:armpl_version) { "#{armpl_major_minor_version}" }
      cached(:armpl_tarball_name) { "arm-performance-libraries_#{armpl_version}_#{package_manager}_gcc.tar" }
      cached(:armpl_url) { "https://bucket.s3.amazonaws.com/archives/armpl/#{armpl_platform}/#{armpl_tarball_name}" }
      cached(:armpl_installer) { "#{sources_dir}/#{armpl_tarball_name}" }
      cached(:armpl_name) { "arm-performance-libraries_#{armpl_version}_#{package_manager}" }
      cached(:gcc_version) { "#{gcc_major_minor_version}.#{gcc_patch_version}" }
      cached(:gcc_url) { "https://bucket.s3.amazonaws.com/archives/dependencies/gcc/gcc-#{gcc_version}.tar.gz" }
      cached(:gcc_tarball) { "#{sources_dir}/gcc-#{gcc_version}.tar.gz" }
      cached(:gcc_modulefile) { "/opt/arm/armpl/#{armpl_version}/modulefiles/armpl/gcc-#{gcc_major_minor_version}" }

      context "when arm_pl is not supported" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['arm_pl']) do |node|
            node.override['conditions']['arm_pl_supported'] = false
            node.override['cluster']['artifacts_s3_url'] = "https://bucket.s3.amazonaws.com/archives"
            node.override['cluster']['armpl']['version'] = armpl_version
          end
          ConvergeArmPl.setup(runner)
        end

        it "doesn't set up arm_pl" do
          is_expected.not_to run_bash("install arm performance library")
        end
      end

      # not_if { ::File.exist?("/opt/arm/armpl/#{armpl_version}") }
      context "when arm_pl is supported" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['arm_pl']) do |node|
            node.override['conditions']['arm_pl_supported'] = true
            node.override['cluster']['sources_dir'] = sources_dir
            node.override['cluster']['region'] = aws_region
            node.override['cluster']['artifacts_s3_url'] = "https://bucket.s3.amazonaws.com/archives"
            node.override['cluster']['armpl']['version'] = armpl_version
          end
          allow_any_instance_of(Object).to receive(:aws_domain).and_return(aws_domain)
          ConvergeArmPl.setup(runner)
        end
        cached(:node) { chef_run.node }

        it 'sets up arm_pl' do
          is_expected.to setup_arm_pl('setup')
        end

        it 'creates sources directory' do
          is_expected.to create_directory(sources_dir).with_recursive(true)
        end

        it 'sets up environment modules' do
          is_expected.to setup_modules('Prerequisite: Environment modules')
        end

        it 'sets up build tools' do
          is_expected.to setup_build_tools('Prerequisite: build tools')
        end

        it 'installs utility packages' do
          is_expected.to install_package(%w(wget bzip2))
        end

        it 'installs prereuisites' do
          if platform == 'centos'
            is_expected.to install_package('centos-release-scl-rh')
            is_expected.to install_package('devtoolset-8-binutils')
          end
        end

        it 'download ArmPL tarball' do
          is_expected.to create_remote_file(armpl_installer).with(
            source: armpl_url,
            mode: '0644',
            retries: 3,
            retry_delay: 5
          )
        end

        it 'installs arm performance library' do
          is_expected.to run_bash('install arm performance library')
            .with_cwd(sources_dir)
            .with_creates("/opt/arm/armpl/#{armpl_version}")
        end

        it 'creates armpl module directory' do
          is_expected.to create_directory("#{modulefile_dir}/armpl")
        end

        it 'creates arm performance library modulefile configuration' do
          armpl_license_dir = "/opt/arm/armpl/#{armpl_version}/arm-performance-libraries_#{armpl_version}_gcc/license_terms"
          is_expected.to create_template("#{modulefile_dir}/armpl/#{armpl_version}").with(
            source: 'arm_pl/armpl_modulefile.erb',
            user: 'root',
            group: 'root',
            mode: '0755',
            variables: {
              armpl_version: armpl_version,
              armpl_license_dir: armpl_license_dir,
              gcc_major_minor_version: gcc_major_minor_version,
            }
          )
        end

        it 'downloads gcc tarball' do
          is_expected.to create_if_missing_remote_file(gcc_tarball).with(
            source: gcc_url,
            mode: '0644',
            retries: 5,
            retry_delay: 10,
            ssl_verify_mode: :verify_none
          )
        end

        it 'installs gcc' do
          is_expected.to run_bash('make install').with(
            user: 'root',
            group: 'root',
            cwd: sources_dir,
            retries: 5,
            retry_delay: 10,
            creates: '/opt/arm/armpl/gcc'
          )
        end

        it 'created gcc modulefile configuration' do
          is_expected.to create_template(gcc_modulefile).with(
            source: 'arm_pl/gcc_modulefile.erb',
            user: 'root',
            group: 'root',
            mode: '0755',
            variables: { gcc_version: gcc_version }
          )
        end

        it 'sets node attributes' do
          expect(node['cluster']['armpl']['version']).to eq(armpl_version)
          expect(node['cluster']['armpl']['gcc']['major_minor_version']).to eq(gcc_major_minor_version)
          expect(node['cluster']['armpl']['gcc']['patch_version']).to eq(gcc_patch_version)
          expect(node['cluster']['armpl']['gcc']['version']).to eq(gcc_version)

          is_expected.to write_node_attributes("dump node attributes")
        end
      end
    end
  end
end

# Tests for ArmPL and gcc download URL construction for the default S3 base_url and an overridden ArmPL base_url.
# The default S3 mirror partitions ArmPL tarballs by platform directory; an overridden base_url skips the platform
# segment. gcc is always downloaded from the S3 mirror.
describe 'arm_pl download URL construction' do
  S3_ARTIFACTS_URL = 'https://REGION-aws-parallelcluster.s3.REGION.AWS_DOMAIN'.freeze
  S3_ARMPL_BASE_URL = "#{S3_ARTIFACTS_URL}/armpl".freeze
  S3_GCC_BASE_URL = "#{S3_ARTIFACTS_URL}/dependencies/gcc".freeze
  PUBLIC_ARMPL_BASE_URL = 'https://fake-public.example.DOMAIN/armpl'.freeze
  ARMPL_VERSION = '99.99'.freeze
  SOURCES_DIR = 'SOURCES_DIR'.freeze

  ARMPL_PLATFORM_DIRS = {
    'amazon2023' => 'RHEL-9',
    'ubuntu22.04' => 'Ubuntu-22.04',
    'ubuntu24.04' => 'Ubuntu-24.04',
    'redhat8' => 'RHEL-8',
    'redhat9' => 'RHEL-9',
    'rocky8' => 'RHEL-8',
    'rocky9' => 'RHEL-9',
  }.freeze
  GCC_MAJOR_MINOR = {
    'amazon2023' => '11.3',
    'ubuntu22.04' => '11.3',
    'ubuntu24.04' => '11.3',
    'redhat8' => '9.3',
    'redhat9' => '11.3',
    'rocky8' => '9.3',
    'rocky9' => '11.3',
  }.freeze

  for_all_oses do |platform, version|
    package_manager = (platform == 'ubuntu') ? 'deb' : 'rpm'
    armpl_tarball = "arm-performance-libraries_#{ARMPL_VERSION}_#{package_manager}_gcc.tar"
    # gcc major.minor is platform-specific and the patch defaults to 0 (gcc is a
    # platform-pinned build tool, not overridable via attributes).
    gcc_tarball = "gcc-#{GCC_MAJOR_MINOR["#{platform}#{version}"]}.0.tar.gz"

    [
      ['default S3 base_url',
       nil,
       "#{S3_ARMPL_BASE_URL}/#{ARMPL_PLATFORM_DIRS["#{platform}#{version}"]}/#{armpl_tarball}"],
      ['overridden public base_url',
       PUBLIC_ARMPL_BASE_URL,
       "#{PUBLIC_ARMPL_BASE_URL}/#{armpl_tarball}"],
    ].each do |scenario, armpl_base_url, expected_armpl_url|
      context "on #{platform}#{version} with #{scenario}" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['arm_pl']) do |node|
            node.override['conditions']['arm_pl_supported'] = true
            node.override['cluster']['sources_dir'] = SOURCES_DIR
            node.override['cluster']['artifacts_s3_url'] = S3_ARTIFACTS_URL
            node.override['cluster']['armpl']['version'] = ARMPL_VERSION
            node.override['cluster']['armpl']['base_url'] = armpl_base_url if armpl_base_url
          end
          ConvergeArmPl.setup(runner)
        end

        it 'downloads the ArmPL tarball from the expected URL' do
          is_expected.to create_remote_file("#{SOURCES_DIR}/#{armpl_tarball}").with_source(expected_armpl_url)
        end

        it 'downloads the gcc tarball from the S3 mirror' do
          is_expected.to create_if_missing_remote_file("#{SOURCES_DIR}/#{gcc_tarball}").with_source("#{S3_GCC_BASE_URL}/#{gcc_tarball}")
        end
      end
    end
  end
end
