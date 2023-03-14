action :update_search_domain_redhat do
  Chef::Log.info("Appending search domain '#{node['cluster']['dns_domain']}' to /etc/dhcp/dhclient.conf")
  # Configure dhclient to automatically append Route53 search domain in resolv.conf
  replace_or_add "append Route53 search domain in /etc/dhcp/dhclient.conf" do
    path "/etc/dhcp/dhclient.conf"
    pattern "append domain-name*"
    line "append domain-name \" #{node['cluster']['dns_domain']}\";"
  end
end
