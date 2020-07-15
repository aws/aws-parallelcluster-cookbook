# Make sure Vagrant user is on the box. This should fix the dokken user install
user 'vagrant'

group 'vagrant' do
  members 'vagrant'
end

directory '/home/vagrant' do
  owner 'vagrant'
  group 'vagrant'
end
