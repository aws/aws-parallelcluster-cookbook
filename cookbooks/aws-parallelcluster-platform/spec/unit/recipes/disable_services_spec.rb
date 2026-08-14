require 'spec_helper'

DISABLE_SERVICE_NAME = 'service_name1 service_name_2'.freeze

describe 'aws-parallelcluster-platform::disable_services' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = ChefSpec::Runner.new do |node|
          node.override['cluster']['disable_services'] = DISABLE_SERVICE_NAME
        end
        runner.converge(described_recipe)
      end

      it 'disables DLAMI multi eni helper' do
        is_expected.to disable_service('aws-ubuntu-eni-helper')
        is_expected.to stop_service('aws-ubuntu-eni-helper')
        is_expected.to mask_service('aws-ubuntu-eni-helper')
      end

      it 'disables log4j CVE 2021-44228 hotpatch' do
        is_expected.to disable_service('log4j-cve-2021-44228-hotpatch')
        is_expected.to stop_service('log4j-cve-2021-44228-hotpatch')
        is_expected.to mask_service('log4j-cve-2021-44228-hotpatch')
      end

      it 'disables dnf-makecache timer' do
        is_expected.to disable_service('dnf-makecache.timer')
        is_expected.to stop_service('dnf-makecache.timer')
      end

      it 'disables fwupd-refresh timer' do
        is_expected.to disable_service('fwupd-refresh.timer')
        is_expected.to stop_service('fwupd-refresh.timer')
        is_expected.to mask_service('fwupd-refresh.timer')
      end

      DISABLE_SERVICE_NAME.split().each do |service_name|
        it "disables #{service_name}" do
          is_expected.to disable_service(service_name)
          is_expected.to stop_service(service_name)
          is_expected.to mask_service(service_name)
        end
      end
    end
  end
end
