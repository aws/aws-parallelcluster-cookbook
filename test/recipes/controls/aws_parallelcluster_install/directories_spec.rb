control 'pcluster_directories_exist' do
  title 'Setup of ParallelCluster directories'

  base_dir = "/opt/parallelcluster"
  dirs = [ base_dir, "#{base_dir}/sources", "#{base_dir}/scripts", "#{base_dir}/licenses", "#{base_dir}/configs", "#{base_dir}/shared" ]
  dirs.each do |path|
    describe directory(path) do
      it { should exist }
    end
  end
end

control 'pcluster_log_dir_is_configured' do
  title 'Setup of ParallelCluster log folder'

  describe directory("/var/log/parallelcluster") do
    it { should exist }
    its('owner') { should eq 'root' }
    its('mode') { should cmp '01777' }
  end
end
