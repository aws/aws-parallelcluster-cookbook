return if on_docker?

raid_and_ebs_dirs = %w(ebs1 /ebs2)
raid_and_ebs_dirs.each do |dir|
  directory dir do
    mode '1777'
  end
end

dirs_to_export = %w(/ebs1 /ebs2)
dirs_to_export.each do |dir|
  nfs_export dir do
    network '127.0.0.1/32'
    writeable true
    options ['no_root_squash']
  end
end
