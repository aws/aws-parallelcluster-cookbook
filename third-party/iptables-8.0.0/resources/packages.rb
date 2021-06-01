unified_mode true

include Iptables::Cookbook::Helpers

property :packages, Array,
  default: lazy { package_names },
  description: 'The packages to install for iptables'

action :install do
  package 'iptables' do
    package_name new_resource.packages
    action :install
  end
end

action :remove do
  package 'iptables' do
    package_name new_resource.packages
    action :remove
  end
end
