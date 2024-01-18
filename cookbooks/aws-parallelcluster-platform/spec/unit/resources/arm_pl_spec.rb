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
        '23.10'
      end

      cached(:armpl_platform) do
        case platform
        when 'centos'
          'RHEL-7'
        when 'ubuntu'
          "Ubuntu-#{version}"
        when 'amazon'
          "AmazonLinux-2"
        else
          "RHEL-#{version}"
        end
      end

      cached(:gcc_major_minor_version) do
        if platform == 'ubuntu' && version == '22.04' || version == '9'
          '11.3'
        else
          '9.3'
        end
      end

      cached(:gcc_patch_version) { '0' }
      cached(:sources_dir) { 'sources_test_dir' }
      cached(:modulefile_dir) { platform == 'ubuntu' ? '/usr/share/modules/modulefiles' : '/usr/share/Modules/modulefiles' }
      cached(:armpl_version) { "#{armpl_major_minor_version}" }
      cached(:armpl_tarball_name) { "arm-performance-libraries_#{armpl_version}_#{armpl_platform}_gcc-#{gcc_major_minor_version}.tar" }
      cached(:armpl_url) { "https://#{aws_region}-aws-parallelcluster.s3.#{aws_region}.#{aws_domain}/archives/armpl/#{armpl_platform}/#{armpl_tarball_name}" }
      cached(:armpl_installer) { "#{sources_dir}/#{armpl_tarball_name}" }
      cached(:armpl_name) { "arm-performance-libraries_#{armpl_version}_#{armpl_platform}" }
      cached(:gcc_version) { "#{gcc_major_minor_version}.#{gcc_patch_version}" }
      cached(:gcc_url) { "https://ftp.gnu.org/gnu/gcc/gcc-#{gcc_version}/gcc-#{gcc_version}.tar.gz" }
      cached(:gcc_tarball) { "#{sources_dir}/gcc-#{gcc_version}.tar.gz" }
      cached(:gcc_modulefile) { "/opt/arm/armpl/#{armpl_version}/modulefiles/armpl/gcc-#{gcc_major_minor_version}" }

      context "when arm_pl is not supported" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['arm_pl']) do |node|
            node.override['conditions']['arm_pl_supported'] = false
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
          armpl_license_dir = if armpl_major_minor_version == "21.0"
                                "/opt/arm/armpl/#{armpl_version}/arm-performance-libraries_#{armpl_major_minor_version}_gcc-#{gcc_major_minor_version}/license_terms"
                              else
                                "/opt/arm/armpl/#{armpl_version}/arm-performance-libraries_#{armpl_version}_gcc-#{gcc_major_minor_version}/license_terms"
                              end
          is_expected.to create_template("#{modulefile_dir}/armpl/#{armpl_version}").with(
            source: 'arm_pl/armpl_modulefile.erb',
            user: 'root',
            group: 'root',
            mode: '0755',
            variables: {
              armpl_version: armpl_version,
              armpl_major_minor_version: armpl_major_minor_version,
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
          expect(node['cluster']['armpl']['major_minor_version']).to eq(armpl_major_minor_version)
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
