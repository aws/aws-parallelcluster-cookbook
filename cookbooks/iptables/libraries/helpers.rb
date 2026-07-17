#
# Cookbook:: iptables
# Library:: chain
#
# Copyright:: 2019, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Iptables
  module Cookbook
    module Helpers
      def get_service_name(ip_version)
        # This function will return the service name
        # for the given ip version
        case ip_version
        when :ipv4
          'iptables'
        when :ipv6
          'ip6tables'
        else
          raise "#{ip_version} is unknown"
        end
      end

      def get_sysconfig_path(ip_version)
        # This function will return the sysconfig path
        # for the given ip version
        case ip_version
        when :ipv4
          '/etc/sysconfig/iptables-config'
        when :ipv6
          '/etc/sysconfig/ip6tables-config'
        else
          raise "#{ip_version} is unknown"
        end
      end

      def get_sysconfig(ip_version)
        # This function will return the sysconfig settings
        # for the given ip version
        case ip_version
        when :ipv4
          {
            'IPTABLES_MODULES' => '',
            'IPTABLES_MODULES_UNLOAD' => 'no',
            'IPTABLES_SAVE_ON_STOP' => 'no',
            'IPTABLES_SAVE_ON_RESTART' => 'no',
            'IPTABLES_SAVE_COUNTER' => 'no',
            'IPTABLES_STATUS_NUMERIC' => 'yes',
            'IPTABLES_STATUS_VERBOSE' => 'no',
            'IPTABLES_STATUS_LINENUMBERS' => 'yes',
          }
        when :ipv6
          {
            'IP6TABLES_MODULES' => '',
            'IP6TABLES_MODULES_UNLOAD' => 'no',
            'IP6TABLES_SAVE_ON_STOP' => 'no',
            'IP6TABLES_SAVE_ON_RESTART' => 'no',
            'IP6TABLES_SAVE_COUNTER' => 'no',
            'IP6TABLES_STATUS_NUMERIC' => 'yes',
            'IP6TABLES_STATUS_VERBOSE' => 'no',
            'IP6TABLES_STATUS_LINENUMBERS' => 'yes',
          }
        else
          raise "#{ip_version} is unknown"
        end
      end

      def package_names
        # This function will return all package names
        case node['platform_family']
        when 'rhel'
          if node['platform_version'].to_i < 7
            %w(iptables)
          else
            %w(iptables iptables-services iptables-utils)
          end
        when 'fedora', 'amazon'
          %w(iptables iptables-services iptables-utils)
        when 'debian'
          %w(iptables iptables-persistent)
        else
          raise "#{node['platform_family']} is not known"
        end
      end

      def convert_to_symbol_and_mark_deprecated(parameter_name, parameter_value)
        if parameter_value.class == 'String'
          Chef::Log.warn("Property #{parameter_name} should be a symbol, the property will no longer accept Strings in the next major version (8.0.0)")
        end
        parameter_value.to_sym
      end

      def default_iptables_rules_file(ip_version)
        # This function will look at the node platform
        # and return the correct file on disk location for the config file
        case ip_version
        when :ipv4
          case node['platform_family']
          when 'rhel', 'fedora', 'amazon'
            '/etc/sysconfig/iptables'
          when 'debian'
            '/etc/iptables/rules.v4'
          end
        when :ipv6
          case node['platform_family']
          when 'rhel', 'fedora', 'amazon'
            '/etc/sysconfig/ip6tables'
          when 'debian'
            '/etc/iptables/rules.v6'
          end
        else
          raise "#{ip_version} is unknown"
        end
      end

      def get_default_chains_for_table(table_name)
        # This function will take in a table and look for default chains
        # that should exist for that table, it will then return a structured hash
        # of those chains
        case table_name
        when :filter
          {
            INPUT: 'ACCEPT [0:0]',
            FORWARD: 'ACCEPT [0:0]',
            OUTPUT: 'ACCEPT [0:0]',
          }
        when :mangle
          {
            PREROUTING: 'ACCEPT [0:0]',
            INPUT: 'ACCEPT [0:0]',
            FORWARD: 'ACCEPT [0:0]',
            OUTPUT: 'ACCEPT [0:0]',
            POSTROUTING: 'ACCEPT [0:0]',
          }
        when :nat
          {
            PREROUTING: 'ACCEPT [0:0]',
            OUTPUT: 'ACCEPT [0:0]',
            POSTROUTING: 'ACCEPT [0:0]',
          }
        when :raw
          {
            PREROUTING: 'ACCEPT [0:0]',
            OUTPUT: 'ACCEPT [0:0]',
          }
        when :security
          {
            INPUT: 'ACCEPT [0:0]',
            FORWARD: 'ACCEPT [0:0]',
            OUTPUT: 'ACCEPT [0:0]',
          }
        else
          {}
        end
      end
    end
  end
end
