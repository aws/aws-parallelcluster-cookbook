action :update_search_domain_redhat do
  Chef::Log.info("Appending search domain '#{node['cluster']['dns_domain']}' to #{search_domain_config_path}")
  replace_or_add "append Route53 search domain in #{search_domain_config_path}" do
    path search_domain_config_path
    pattern append_pattern
    line append_line
  end
end

def search_domain_config_path
  # Configure dhclient to automatically append Route53 search domain in resolv.conf
  '/etc/dhcp/dhclient.conf'
end

def append_pattern
  'append domain-name*'
end

def append_line
  "append domain-name \" #{node['cluster']['dns_domain']}\";"
end
