require 'spec_helper'

describe 'aws-parallelcluster-environment:libraries:aws_domain_for_fsx' do
  shared_examples 'a valid aws_domain_for_fsx function' do |region, expected_aws_domain|
    it 'returns the correct AWS domain' do
      result = aws_domain_for_fsx(region)
      expect(result).to eq(expected_aws_domain)
    end
  end

  context 'when in US-ISO region' do
    include_examples 'a valid aws_domain_for_fsx function', 'us-iso-WHATEVER', 'c2s.ic.gov'
  end

  context 'when in US-ISOB region' do
    include_examples 'a valid aws_domain_for_fsx function', 'us-isob-', 'sc2s.sgov.gov'
  end

  context 'when in CN region' do
    include_examples 'a valid aws_domain_for_fsx function', 'cn-WHATEVER', 'amazonaws.com'
  end

  context 'when in GovCloud region' do
    include_examples 'a valid aws_domain_for_fsx function', 'us-gov-WHATEVER', 'amazonaws.com'
  end

  context 'when in whatever else region' do
    include_examples 'a valid aws_domain_for_fsx function', 'WHATEVER-ELSE', 'amazonaws.com'
  end
end
