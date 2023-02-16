action :update_search_domain_ubuntu do
  Chef::Log.info("Appending search domain '#{node['cluster']['dns_domain']}' to /etc/systemd/resolved.conf")
  # Configure resolved to automatically append Route53 search domain in resolv.conf.
  # On Ubuntu18 resolv.conf is managed by systemd-resolved.
  replace_or_add "append Route53 search domain in /etc/systemd/resolved.conf" do
    path "/etc/systemd/resolved.conf"
    pattern "Domains=*"
    line "Domains=#{node['cluster']['dns_domain']}"
  end
end
