require_relative '../../../libraries/helpers'

describe 'get_target_group_name' do
  shared_examples 'a valid target group name generator' do |cluster_name, pool_name, expected_result|
    it 'generates a correctly formatted target group name' do
      target_group_name = get_target_group_name(cluster_name, pool_name)
      expect(target_group_name).to eq(expected_result)
    end
  end

  context 'when cluster and pool names are regular strings' do
    include_examples 'a valid target group name generator', 'test-cluster', 'test-pool', 'test-cl-test-po-18c74b16dfbc78ac'
  end

  context 'when cluster and pool names are longer strings' do
    include_examples 'a valid target group name generator', 'abcdefghijklmnopqrstuvwxyz', 'zyxwvutsrqponmlkjihgfedcba', 'abcdefg-zyxwvut-20f1fcdf919164c7'
  end

  context 'when cluster and pool names are single characters' do
    include_examples 'a valid target group name generator', 'a', 'b', 'a-b-fb8e20fc2e4c3f24'
  end
end
