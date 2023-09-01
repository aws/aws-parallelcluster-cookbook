resource_name :munge_key_manager
provides :munge_key_manager
unified_mode true

property :munge_key_secret_arn, String

default_action :manage

action :manage do
  if new_resource.munge_key_secret_arn
    # This block will fetch the munge key from Secrets Manager
    bash 'fetch_and_decode_munge_key' do
      user 'root'
      cwd '/tmp'
      code <<-FETCH_AND_DECODE
        encoded_key=$(aws secretsmanager get-secret-value --secret-id #{new_resource.munge_key_secret_arn} --query 'SecretString' --output text)
        echo $encoded_key | base64 -d > /etc/munge/munge.key
        chmod 0600 /etc/munge/munge.key
      FETCH_AND_DECODE
    end
  else
    # This block will generate a munge key if it doesn't exist
    bash 'generate_munge_key' do
      not_if { ::File.exist?('/etc/munge/munge.key') }
      user node['cluster']['munge']['user']
      group node['cluster']['munge']['group']
      cwd '/tmp'
      code <<-GENERATE_KEY
        set -e
        /usr/sbin/mungekey --verbose
        chmod 0600 /etc/munge/munge.key
      GENERATE_KEY
    end
  end
end
