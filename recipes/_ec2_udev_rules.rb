
cookbook_file 'ec2-volid.rules' do
  path '/etc/udev/rules.d/52-ec2-volid.rules'
  user 'root'
  group 'root'
  mode '0644'
end

cookbook_file 'ec2_dev_2_volid.py' do
  path '/sbin/ec2_dev_2_volid.py'
  user 'root'
  group 'root'
  mode '0744'
end

cookbook_file 'ec2blkdev-init' do
  path '/etc/init.d/ec2blkdev'
  user 'root'
  group 'root'
  mode '0744'
end

cookbook_file 'attachVolume.py' do
  path '/usr/local/sbin/attachVolume.py'
  user 'root'
  group 'root'
  mode '0755'
end

service "ec2blkdev" do
  supports :restart => true
  action [ :enable, :start ]
end