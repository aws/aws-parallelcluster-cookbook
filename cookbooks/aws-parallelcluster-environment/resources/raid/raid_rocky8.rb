provides :raid, platform: 'rocky' do |node|
  node['platform_version'].to_i >= 8
end

use 'partial/_raid_common'

action_class do
  def raid_superblock_version
    '1.2'
  end
end
