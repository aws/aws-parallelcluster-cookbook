require 'spec_helper'

describe 'aws-parallelcluster-platform::disable_services' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version).converge(described_recipe)
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

      it 'disables cups' do
        is_expected.to disable_service('cups')
        is_expected.to stop_service('cups')
        is_expected.to mask_service('cups')
      end

      it 'disables wpa_supplicant' do
        is_expected.to disable_service('wpa_supplicant')
        is_expected.to stop_service('wpa_supplicant')
        is_expected.to mask_service('wpa_supplicant')
      end
    end
  end
end
