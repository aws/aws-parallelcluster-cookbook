provides :manage_raid, platform: 'ubuntu', platform_version: '20.04'

use 'partial/_raid_configuration'

action_class do
  def raid_superblock_version
    '1.2'
  end
end
