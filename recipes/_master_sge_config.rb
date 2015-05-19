# Export /opt/sge
nfs_export "/opt/sge" do
  network node['cfncluster']['ec2-metadata']['vpc-ipv4-cidr-block']
  writeable true
  options ['no_root_squash']
end

# Put sge_inst in place
cookbook_file 'sge_inst.conf' do
  path '/opt/sge/sge_inst.conf'
  user 'root'
  group 'root'
  mode '0644'
end

# Run inst_sge
execute "inst_sge" do
  command './inst_sge -m -auto ./sge_inst.conf'
  cwd '/opt/sge'
  not_if { ::File.exists?('/opt/sge/default/common/cluster_name') }
end

link "/etc/profile.d/sge.sh" do
  to "/opt/sge/default/common/settings.sh"
end

link "/etc/profile.d/sge.csh" do
  to "/opt/sge/default/common/settings.csh"
end

service "sgemaster.p6444" do
  supports :restart => false
  action [ :enable, :start ]
end

bash "add_host_as_master" do
  code <<-EOH
    . /opt/sge/default/common/settings.sh
    qconf -as #{node['hostname']}
  EOH
end  

template '/opt/cfncluster/scripts/publish_pending' do
  source 'publish_pending.sge.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

cron 'publish_pending' do
  command '/opt/cfncluster/scripts/publish_pending'
end

