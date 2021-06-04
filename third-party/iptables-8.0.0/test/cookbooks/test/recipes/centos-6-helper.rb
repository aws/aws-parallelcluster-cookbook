# CentOS 6 on Bento requires the iptables modules loading

%w(ip_tables iptable_filter iptable_mangle iptable_nat).each do |mod|
  next if node['kernel']['modules'].keys.include?(mod)

  execute "modprobe #{mod}" do
    returns [0, 1]
  end
end
