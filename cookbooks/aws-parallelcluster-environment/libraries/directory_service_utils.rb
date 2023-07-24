# Parse an ARN.
# ARN format: arn:PARTITION:SERVICE:REGION:ACCOUNT_ID:RESOURCE.
# ARN examples:
#   1. arn:aws:secretsmanager:eu-west-1:12345678910:secret:PasswordName
#   2. arn:aws:ssm:eu-west-1:12345678910:parameter/PasswordName
def parse_arn(arn_string)
  parts = arn_string.nil? ? [] : arn_string.split(':', 6)
  raise TypeError if parts.size < 6

  {
    partition: parts[1],
    service: parts[2],
    region: parts[3],
    account_id: parts[4],
    resource: parts[5],
  }
end

# Parse parameter DomainReadOnlyUser: cn=ReadOnlyUser,ou=Users,ou=CORP,dc=corp,dc=sirena,dc=com
# and return the "cn=<user-name> section if present
def _get_cn_subparam(param)
  tokens = param.split(",") unless param.blank?
  tokens.each do |token|
    return token if token.include? "cn"
  end
  ""
end

# Parse parameter DomainReadOnlyUser: cn=ReadOnlyUser,ou=Users,ou=CORP,dc=corp,dc=sirena,dc=com
# Retrieve the configured name for the Directory Service ReadOnly user
# If DomainReadOnlyUser is non well configured returns a default 'ReadOnlyUser' name
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
