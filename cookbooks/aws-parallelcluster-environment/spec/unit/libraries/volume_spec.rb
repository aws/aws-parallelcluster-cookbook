require 'spec_helper'

describe 'aws-parallelcluster-environment:libraries:format_directory' do
  it 'adds / at the beginning if not starting with /' do
    expect(format_directory('any')).to eq('/any')
  end

  it 'does not add / at the beginning if already starting with /' do
    expect(format_directory('/any')).to eq('/any')
  end

  it 'strips whitespaces from directory' do
    expect(format_directory('  any ')).to eq('/any')
  end
end
