require 'spec_helper'

class ConvergeDnsDomain
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-slurm') do
      dns_domain 'setup' do
        action :setup
      end
    end
  end

  def self.configure(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-slurm') do
      dns_domain 'configure' do
        action :configure
      end
    end
  end
end

describe 'dns_domain:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['dns_domain'])
        ConvergeDnsDomain.setup(runner)
      end

      it 'sets up dns_domain' do
        is_expected.to setup_dns_domain('setup')
      end

      it 'installs hostname package' do
        is_expected.to install_package('hostname').with_retries(3).with_retry_delay(5)
      end
    end
  end
end

describe 'dns_domain:configure' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:dns_domain) { 'dns_domain' }
      cached(:search_domain_config_path) { platform == 'ubuntu' ? '/etc/systemd/resolved.conf' : '/etc/dhcp/dhclient.conf' }
      cached(:append_pattern) { platform == 'ubuntu' ? 'Domains=*' : 'append domain-name*' }
      cached(:append_line) { platform == 'ubuntu' ? "Domains=#{dns_domain}" : "append domain-name \" #{dns_domain}\";" }

      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['dns_domain']) do |node|
          node.override['cluster']['dns_domain'] = dns_domain
        end
        ConvergeDnsDomain.configure(runner)
      end

      it 'configures dns_domain' do
        is_expected.to configure_dns_domain('configure')
      end

      it 'updates search domaint' do
        is_expected.to edit_replace_or_add("append Route53 search domain in #{search_domain_config_path}").with(
          path: search_domain_config_path,
          pattern: append_pattern,
          line: append_line
        )
      end

      it 'restarts network service' do
        is_expected.to restart_network_service('Restart network service')
      end

      if platform == 'redhat'
        it 'creates NetworkManager.conf' do
          is_expected.to create_cookbook_file('NetworkManager.conf').with(
            path: '/etc/NetworkManager/NetworkManager.conf',
            source: 'dns_domain/NetworkManager.conf',
            user: 'root',
            group: 'root',
            mode: '0644'
          )
        end
      end
    end
  end
end
