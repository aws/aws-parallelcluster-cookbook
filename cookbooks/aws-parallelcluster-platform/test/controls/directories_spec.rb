control 'tag:install_pcluster_directories_exist' do
  title 'Setup of ParallelCluster directories'

  base_dir = "/opt/parallelcluster"
  dirs = [ base_dir, "#{base_dir}/sources", "#{base_dir}/scripts", "#{base_dir}/licenses", "#{base_dir}/configs", "#{base_dir}/shared", "#{base_dir}/tmp" ]
  dirs.each do |path|
    describe directory(path) do
      it { should exist }
    end
  end

  # The dedicated executable temp directory must be root-owned and not world-writable.
  describe directory("#{base_dir}/tmp") do
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end
end

control 'tag:install_pcluster_log_dir_is_configured' do
  title 'Setup of ParallelCluster log folder'

  describe directory("/var/log/parallelcluster") do
    it { should exist }
    its('owner') { should eq 'root' }
    its('mode') { should cmp '01777' }
  end
end
