#
# Verify the results of using the stanza filter
#

template '/tmp/stanza' do
  source 'stanza.erb'
  action :create_if_missing
end

filter_lines 'Change stanza values' do
  path '/tmp/stanza'
  sensitive false
  filters(
    [
      { stanza:  ['libvas', { 'use-dns-srv' => false, 'mscldap-timeout' => 5 }] },
      { stanza:  ['nss_vas', { 'lowercase-names' => false, addme: 'option' }] },
      { stanza:  ['test1', { line1: 'true' }] },
      { stanza:  ['test2/test', { line1: 'false' }] },
    ]
  )
end

# Add a test for an invalid stanza name
filter_lines 'Fail stanza change' do
  path '/tmp/stanza'
  ignore_failure true
  sensitive false
  filters(
    [
      { stanza:  ['test2!test', { line1: 'false' }] },
    ]
  )
end
