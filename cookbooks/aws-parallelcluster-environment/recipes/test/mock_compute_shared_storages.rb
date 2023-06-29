return if on_docker?

# We create an empty /opt/intel directory, because for the test we
# only need the folder to be present, and this way we can speed
# things up by avoiding the installation of Intel MPI
directory '/opt/intel'

dirs_to_export = %w(/opt/intel)
dirs_to_export.each do |dir|
  nfs_export dir do
    network '127.0.0.1/32'
    writeable true
    options ['no_root_squash']
  end
end
