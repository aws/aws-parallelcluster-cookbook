provides :manage_raid

use 'partial/_raid_configuration'

action_class do
  def raid_superblock_version
    '0.90'
  end
end
