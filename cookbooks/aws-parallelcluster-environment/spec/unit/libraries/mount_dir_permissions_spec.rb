require 'spec_helper'

describe 'aws-parallelcluster-environment:libraries:mount_dir_mode' do
  it 'returns the configured mode' do
    expect(mount_dir_mode('0750', '1777')).to eq('0750')
  end

  it 'returns NONE' do
    expect(mount_dir_mode('NONE', '1777')).to eq('NONE')
  end

  it 'returns the default mode for DEFAULT or no value' do
    expect(mount_dir_mode('DEFAULT', '1777')).to eq('1777')
    expect(mount_dir_mode(nil, '755')).to eq('755')
  end
end

describe 'aws-parallelcluster-environment:libraries:default_mount_dir_mode' do
  it 'returns 755 for /home and 1777 for the other mount directories' do
    expect(default_mount_dir_mode('/home')).to eq('755')
    expect(default_mount_dir_mode('home')).to eq('755')
    expect(default_mount_dir_mode('/shared')).to eq('1777')
  end
end

describe 'aws-parallelcluster-environment:libraries:find_storage_in_mapping' do
  let(:storage) { { 'efs_fs_id' => 'fs-1', 'mount_dir' => '/efs', 'mount_dir_permissions' => 'DEFAULT' } }

  it 'finds the same storage with different mount dir permissions' do
    entries = [{ 'efs_fs_id' => 'fs-1', 'mount_dir' => '/efs', 'mount_dir_permissions' => '0750' }]
    expect(find_storage_in_mapping(entries, storage)).to eq(entries.first)
  end

  it 'does not find a storage with a different mount dir' do
    entries = [{ 'efs_fs_id' => 'fs-1', 'mount_dir' => '/other', 'mount_dir_permissions' => 'DEFAULT' }]
    expect(find_storage_in_mapping(entries, storage)).to be_nil
  end

  it 'does not find a storage in no entries' do
    expect(find_storage_in_mapping(nil, storage)).to be_nil
  end
end

describe 'aws-parallelcluster-environment:libraries:mount_dir_permissions_changes' do
  def ebs(mount_dir, permissions)
    { 'volume_id' => "vol-#{mount_dir.delete('/')}", 'mount_dir' => mount_dir, 'mount_dir_permissions' => permissions }
  end

  let(:previous_mapping) do
    {
      'ebs' => [ebs('/ebs1', 'DEFAULT'), ebs('/ebs2', '0750'), ebs('/ebs3', '0750'), ebs('/ebs4', 'DEFAULT'),
                ebs('/home', '0700'), ebs('/ebs5', '0750')],
      'raid' => [{ 'raid_shared_dir' => 'raid', 'raid_type' => 0, 'raid_vol_array' => %w(vol-a vol-b), 'mount_dir_permissions' => 'DEFAULT' }],
      'efs' => [],
      'fsx' => [{ 'fsx_fs_id' => 'fs-z', 'fsx_fs_type' => 'OPENZFS', 'mount_dir' => '/zfs', 'mount_dir_permissions' => 'DEFAULT' }],
    }
  end

  let(:new_mapping) do
    {
      # /ebs1: unchanged, /ebs2: new mode, /ebs3: back to the default, /ebs4: left unchanged with NONE,
      # /home: back to its default, /ebs6: new storage, mounted with its permissions
      'ebs' => [ebs('/ebs1', 'DEFAULT'), ebs('/ebs2', '0700'), ebs('/ebs3', 'DEFAULT'), ebs('/ebs4', 'NONE'),
                ebs('/home', 'DEFAULT'), ebs('/ebs6', '0750')],
      'raid' => [{ 'raid_shared_dir' => 'raid', 'raid_type' => 0, 'raid_vol_array' => %w(vol-a vol-b), 'mount_dir_permissions' => '0755' }],
      'efs' => [],
      'fsx' => [{ 'fsx_fs_id' => 'fs-z', 'fsx_fs_type' => 'OPENZFS', 'mount_dir' => '/zfs', 'mount_dir_permissions' => '0755' }],
    }
  end

  it 'returns no storage when nothing changes, also with node attributes' do
    # The mappings are node attributes in the update recipe, read back as Chef::Node::ImmutableMash
    node = Chef::Node.new
    node.default['cluster']['previous_mapping'] = previous_mapping
    node.default['cluster']['new_mapping'] = previous_mapping
    changes = mount_dir_permissions_changes(node['cluster']['previous_mapping'], node['cluster']['new_mapping'])
    expect(changes.values.flatten).to be_empty
  end

  it 'returns the storage whose permissions change, also with node attributes' do
    node = Chef::Node.new
    node.default['cluster']['previous_mapping'] = previous_mapping
    node.default['cluster']['new_mapping'] = new_mapping
    changes = mount_dir_permissions_changes(node['cluster']['previous_mapping'], node['cluster']['new_mapping'])
    expect(changes['ebs'].map { |storage| [storage['mount_dir'], storage['mount_dir_permissions']] }).to eq(
      [%w(/ebs2 0700), %w(/ebs3 1777), %w(/home 755)]
    )
  end

  it 'returns the storage that stays mounted and whose permissions change, with the mode to set' do
    changes = mount_dir_permissions_changes(previous_mapping, new_mapping)
    expect(changes['ebs']).to eq([ebs('/ebs2', '0700'), ebs('/ebs3', '1777'), ebs('/home', '755')])
    expect(changes['raid'].map { |storage| [storage['raid_shared_dir'], storage['mount_dir_permissions']] }).to eq([%w(raid 0755)])
    expect(changes['efs']).to eq([])
    # FSx for OpenZFS is skipped by the lustre resource
    expect(changes['fsx'].map { |storage| storage['mount_dir_permissions'] }).to eq(%w(0755))
  end
end
