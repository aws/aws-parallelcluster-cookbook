provides :raid, platform: 'amazon' do |node|
  node['platform_version'].to_i == 2023
end

use 'partial/_raid_common'

action_class do
  def raid_superblock_version
    '1.2'
  end
end
