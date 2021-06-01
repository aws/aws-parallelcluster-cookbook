unified_mode true

include Iptables::Cookbook::Helpers

property :table, [Symbol, String],
          equal_to: [:filter, :mangle, :nat, :raw, :security, 'filter', 'mangle', 'nat', 'raw', 'security'],
          default: :filter,
          description: 'The table the chain should exist on'

property :chain, [Symbol, String],
          description: 'The name of the Chain'

property :value, String,
          default: 'ACCEPT [0:0]',
          description: 'The default action and the Packets : Bytes count'

property :ip_version, Symbol,
          equal_to: %i(ipv4 ipv6),
          default: :ipv6,
          description: 'The IP version, 4 or 6'

property :file_mode, String,
          default: '0644',
          description: 'Permissions on the saved output file'

property :source_template, String,
          default: 'iptables.erb',
          description: 'Source template to use to create the rules'

property :cookbook, String,
          default: 'iptables',
          description: 'Source cookbook to find the template in'

property :sensitive, [true, false],
          default: false,
          description: 'mark the resource as senstive'

property :config_file, String,
          default: lazy { default_iptables_rules_file(ip_version) },
          description: 'The full path to find the rules on disk'

action :create do
  Chef::Log.warn('iptables_chain6 is deprecated, please use the normal iptable_chain with property ip_version set to :ipv6')
  iptables_chain new_resource.name do
    table new_resource.table
    chain new_resource.chain
    value new_resource.value
    ip_version new_resource.ip_version
    file_mode new_resource.file_mode
    source_template new_resource.source_template
    cookbook  new_resource.cookbook
    sensitive new_resource.sensitive
    config_file new_resource.config_file
  end
end
