# Mount /opt/sge over NFS
nfs_master = "#{node['cfncluster']['cfn_master'].split('.')[0]}"
mount '/opt/sge' do
  device "#{nfs_master}:/opt/sge"
  fstype "nfs"
  options 'hard,intr,noatime,vers=3,_netdev'
  action [:mount, :enable]
end

# Setup SGE
link '/etc/profile.d/sge.sh' do
  to '/opt/sge/default/common/settings.sh'
end

link '/etc/profile.d/sge.csh' do
  to '/opt/sge/default/common/settings.csh'
end

directory '/opt/cfncluster/templates'
directory '/opt/cfncluster/templates/sge'
link '/opt/cfncluster/templates/sge/sge_inst.conf' do
  to '/opt/sge/sge_inst.conf'
end
