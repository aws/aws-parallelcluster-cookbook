# This will test that inserting a rule at a given number
# will output the rule correctly

include_recipe '::centos-6-helper' if platform?('centos') && node['platform_version'].to_i == 6

iptables_packages 'install iptables'
iptables_service 'configure iptables services'

iptables_chain 'filter' do
  table :filter
end

iptables_rule 'Allow from loopback interface' do
  table :filter
  chain :INPUT
  ip_version :ipv4
  jump 'ACCEPT'
  in_interface 'lo'
end

# This should be the first rule now
iptables_rule 'Allow from loopback interface' do
  table :filter
  chain :INPUT
  ip_version 'ipv4'
  jump 'ACCEPT'
  in_interface 'eth0'
  line_number 1
end
