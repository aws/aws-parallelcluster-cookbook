require_relative '../../../libraries/environment'
require 'spec_helper'

describe 'aws_domain' do
  shared_examples 'a valid aws_domain function' do |region, expected_aws_domain|
    it 'returns the correct AWS domain' do
      allow_any_instance_of(Object).to receive(:aws_region).and_return(region)
      # We must force aws_domain to call the original function because
      # the spec_helper configures aws_domain to return a mocked value for all rspec tests.
      allow_any_instance_of(Object).to receive(:aws_domain).and_call_original

      expect(aws_domain).to eq(expected_aws_domain)
    end
  end

  context 'when in CN region' do
    include_examples 'a valid aws_domain function', 'cn-WHATEVER', 'amazonaws.com.cn'
  end

  context 'when in US-ISO region' do
    include_examples 'a valid aws_domain function', 'us-iso-WHATEVER', 'c2s.ic.gov'
  end

  context 'when in US-ISOB region' do
    include_examples 'a valid aws_domain function', 'us-isob-', 'sc2s.sgov.gov'
  end

  context 'when in GovCloud region' do
    include_examples 'a valid aws_domain function', 'us-gov-WHATEVER', 'amazonaws.com'
  end

  context 'when in whatever else region' do
    include_examples 'a valid aws_domain function', 'WHATEVER-ELSE', 'amazonaws.com'
  end
end
