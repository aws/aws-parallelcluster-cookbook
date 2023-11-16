require_relative '../../spec_helper'

describe 'config_login' do
  %w(aws-parallelcluster-platform::loginmgtd).each do |component|
    it { is_expected.to include_recipe(component) }
  end
end
