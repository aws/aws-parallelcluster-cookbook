user = "pcluster-admin"

control 'tag:install_users_admin_user_created' do
  title 'Configure cluster admin user'

  describe command("grep #{user} /etc/passwd") do
    its('stdout.strip') { should eq "#{user}:x:400:400:AWS ParallelCluster Admin user:/home/#{user}:/bin/bash" }
  end

  describe user(user) do
    its(:gid) { should eq 400 }
    its(:group) { should eq "pcluster-admin" }
  end
end

control 'tag:install_users_ulimit_configured' do
  title 'Configure soft ulimit nofile'
  describe limits_conf("/etc/security/limits.d/00_all_limits.conf") do
    its('*') { should include ['-', 'nofile', "10000"] }
  end
end

control 'tag:config_admin_user_and_group_correctly_defined' do
  describe user(node['cluster']['cluster_admin_user']) do
    it { should exist }
    its('uid') { should eq node['cluster']['cluster_admin_user_id'] }
    its('gid') { should eq node['cluster']['cluster_admin_group_id'] }
    # "AWS ParallelCluster Admin user"
  end

  describe group(node['cluster']['cluster_admin_group']) do
    it { should exist }
    its('gid') { should eq node['cluster']['cluster_admin_group_id'] }
  end
end

control 'tag:config_ulimit_is_not_lower_than_8192' do
  only_if { !instance.custom_ami? }

  describe bash("ulimit -Sn") do
    its('stdout') { should cmp >= '8192' }
  end
end
