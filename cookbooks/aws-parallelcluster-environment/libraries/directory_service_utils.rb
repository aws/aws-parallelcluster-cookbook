#
# Parse parameter DomainReadOnlyUser: cn=ReadOnlyUser,ou=Users,ou=CORP,dc=corp,dc=sirena,dc=com
# and return the actual Name of the ReadOnly user
def _get_cn_subparam(param)
  tokens = param.split(",") unless param.blank?
  tokens.each do |token|
    return token if token.include? "cn"
  end
  ""
end

def domain_service_read_only_user_name(param)
  cn_token = _get_cn_subparam(param)
  if cn_token.blank?
    Chef::Log.info("Failed to retrieve the ReadOnlyUser from #{param}")
    name = 'ReadOnlyUser'
    Chef::Log.info("Falling back to the default UserName #{name}")
  else
    name = cn_token.split("=")[1]
    Chef::Log.info("UserName for ReadOnly directory service user set to #{name}")
  end

  name
end
