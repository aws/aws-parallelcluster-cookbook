
## Create mocked shared directory to hold Sssd.config
login_node_shared_directory_service_dir = "#{node['cluster']['shared_dir_login_nodes']}/directory_service"
login_node_shared_sssd_conf_path = "#{login_node_shared_directory_service_dir}/sssd.conf"
directory login_node_shared_directory_service_dir do
  owner 'root'
  group 'root'
  mode '0600'
  recursive true
end

file login_node_shared_sssd_conf_path do
  owner 'root'
  group 'root'
  mode '0600'
  content '[domain/default]
access_provider = ldap
cache_credentials = True
debug_level = 0x1ff
default_shell = /bin/bash
fallback_homedir = /home/%u
id_provider = ldap
ldap_access_filter = filter-string
ldap_default_authtok = fake-secret
ldap_default_bind_dn = cn=ReadOnlyUser,ou=Users,ou=CORP,dc=corp,dc=something,dc=com
ldap_id_mapping = True
ldap_referrals = False
ldap_schema = AD
ldap_search_base = DC=corp,DC=something,DC=com
ldap_tls_cacert = /path/to/domain-certificate.crt
ldap_tls_reqcert = never
ldap_uri = ldaps://corp.something.com
use_fully_qualified_names = False

[domain/local]
id_provider = files
enumerate = True

[sssd]
config_file_version = 2
services = nss, pam, ssh
domains = default, local
full_name_format = %1$s

[nss]
filter_users = nobody,root
filter_groups = nobody,root

[pam]
offline_credentials_expiration = 7'
end
