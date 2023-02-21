return if virtualized?

raid_and_ebs_dirs = %w(/exported_raid1 /exported_ebs1 /exported_ebs2)
raid_and_ebs_dirs.each do |dir|
  directory dir do
    mode '1777'
  end
end

# We create an empty /opt/intel directory, because for the test we
# only need the folder to be present, and this way we can speed
# things up by avoiding the installation of Intel MPI
directory '/opt/intel'
directory '/exported_intel'

dirs_to_export = %w(/exported_raid1 /exported_ebs1 /exported_ebs2 /exported_intel)
dirs_to_export.each do |dir|
  nfs_export dir do
    network '127.0.0.1/32'
    writeable true
    options ['no_root_squash']
  end
end
