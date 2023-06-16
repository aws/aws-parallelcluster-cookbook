unified_mode true

include Iptables::Cookbook::Helpers

property :ip_version, Symbol,
          equal_to: %i(ipv4 ipv6),
          default: :ipv4,
          description: 'The IP version, 4 or 6'

property :sysconfig, Hash,
          default: lazy { get_sysconfig(ip_version) },
          description: 'The sysconfig settings'

property :service_name, String,
          default: lazy { get_service_name(ip_version) },
          description: 'Name of the iptables services'

property :sysconfig_file_mode, String,
          default: '0600',
          description: 'Permissions on the saved sysconfig file'

property :file_mode, String,
          default: '0644',
          description: 'Permissions on the saved rules file'

property :source_template, String,
          default: 'iptables-config.erb',
          description: 'Source template to use to create the sysconfig file'

property :cookbook, String,
          default: 'iptables',
          description: 'Source cookbook to find the template in'

property :sysconfig_file, String,
          default: lazy { get_sysconfig_path(ip_version) },
          description: 'The full path to find the sysconfig file on disk'

property :config_file, String,
          default: lazy { default_iptables_rules_file(ip_version) },
          description: 'The full path to find the rules on disk'

action :enable do
  case node['platform_family']
  when 'debian'
    with_run_context :root do
      edit_resource(:service, 'netfilter-persistent') do |new_resource|
        subscribes :restart, "template[#{new_resource.config_file}]", :delayed
        action :enable
      end
    end
  when 'rhel', 'fedora', 'amazon'
    file new_resource.config_file do
      content '# Chef managed placeholder to allow iptables service to start'
      action :create_if_missing
    end

    template new_resource.sysconfig_file do
      source new_resource.source_template
      cookbook new_resource.cookbook
      mode new_resource.sysconfig_file_mode
      variables(
        config: new_resource.sysconfig
      )
    end
    with_run_context :root do
      edit_resource(:service, new_resource.service_name) do |new_resource|
        subscribes :restart, "template[#{new_resource.config_file}]", :delayed
        action [:enable, :start]
      end
    end
  end
end

action :disable do
  case node['platform_family']
  when 'debian'
    service 'netfilter-persistent' do
      action [:disable, :stop]
    end
  when 'rhel', 'fedora', 'amazon'
    file new_resource.config_file do
      content '# iptables rules files cleared by chef via iptables::disabled'
      action :create
    end

    file "#{new_resource.config_file}.fallback" do
      content '# iptables rules files cleared by chef via iptables::disabled'
      action :create
    end

    service new_resource.service_name do
      action [:disable, :stop]
    end
  end
end
