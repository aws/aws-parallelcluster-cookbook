require 'spec_helper'

for_all_oses do |platform, version|
  context "on #{platform}#{version}" do
    describe 'aws-parallelcluster-platform::modules setup' do
      cached(:chef_run) do
        runner(platform: platform, version: version, step_into: ['modules']).converge_dsl('aws-parallelcluster-platform') do
          modules 'setup' do
            action :setup
          end
        end
      end

      it 'sets up modules' do
        is_expected.to setup_modules('setup')
      end

      if platform == 'ubuntu'
        it 'updates package repositories' do
          is_expected.to update_package_repos('update package repos')
        end

        it 'installs packages' do
          is_expected.to install_package(version.to_i == 18 ? %w(tcl-dev environment-modules) : 'environment-modules')
        end
      else
        it 'installs packages' do
          is_expected.to install_package('environment-modules')
        end
      end
    end

    describe 'aws-parallelcluster-platform::modules append_to_config' do
      cached(:line) { 'line_to_append' }
      cached(:modulepath_config_file) do
        case platform
        when 'ubuntu'
          "/usr/share/modules/init/.modulespath"
        when 'redhat'
          '/etc/environment-modules/modulespath'
        else
          "/usr/share/Modules/init/.modulespath"
        end
      end

      cached(:chef_run) do
        the_line = line
        runner(platform: platform, version: version, step_into: ['modules']).converge_dsl('aws-parallelcluster-platform') do
          modules 'append_to_config' do
            line the_line
            action :append_to_config
          end
        end
      end

      it 'appends to config' do
        is_expected.to append_to_config_modules('append_to_config')
      end

      it 'appends line to config file' do
        is_expected.to edit_append_if_no_line('append_to_config').with(
          path: modulepath_config_file,
          line: line
        )
      end
    end
  end
end
