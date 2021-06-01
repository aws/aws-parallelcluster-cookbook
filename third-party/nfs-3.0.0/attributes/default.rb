#
# Cookbook Name:: nfs
# Attributes:: default
#
# Copyright 2011, Eric G. Wolfe
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Allowing Version 2, 3 and 4 of NFS to be enabled or disabled.
# Default behavior, defer to protocol level(s) supported by kernel.
default['nfs']['v2'] = nil
default['nfs']['v3'] = nil
default['nfs']['v4'] = nil

# rquotad needed?
default['nfs']['rquotad'] = 'no'

# Default options are taken from the Debian guide on static NFS ports
default['nfs']['port']['statd'] = 32_765
default['nfs']['port']['statd_out'] = 32_766
default['nfs']['port']['mountd'] = 32_767
default['nfs']['port']['lockd'] = 32_768
default['nfs']['port']['rquotad'] = 32_769

# Number of rpc.nfsd threads to start (default 8)
default['nfs']['threads'] = 8

# Default options are based on RHEL8
default['nfs']['packages'] = if node['platform_family'] == 'debian'
                               %w(nfs-common rpcbind)
                             else
                               %w(nfs-utils rpcbind)
                             end

# rpc-statd doesn't start unless you call nfs-config on Ubuntu
default['nfs']['service']['config'] = if (node['platform'] == 'debian' && node['platform_version'].to_i >= 10) ||
                                         (node['platform'] == 'ubuntu' && node['platform_version'].to_i >= 15)
                                        'nfs-config.service'
                                      end

# Let systemd demand rpcbind
default['nfs']['service']['portmap'] = 'nfs-client.target'

# Ubuntu seems to require nfs-config for rpc-statd to start
default['nfs']['service']['lock'] = if node['platform_family'] == 'debian'
                                      'rpc-statd.service' # force rpc-statd.service on ubuntu, bad unit file?
                                    else
                                      'nfs-client.target' # Let systemd demand rpc-statd on-demand for Enterprise Linux
                                    end

default['nfs']['service']['server'] = if node['platform_family'] == 'debian'
                                        'nfs-kernel-server.service'
                                      else
                                        'nfs-server.service'
                                      end

# Client config defaults
default['nfs']['config']['client_templates'] = if node['platform_family'] == 'debian'
                                                 %w(/etc/default/nfs-common /etc/modprobe.d/lockd.conf)
                                               else
                                                 %w(/etc/sysconfig/nfs /etc/modprobe.d/lockd.conf)
                                               end

# Sever config defaults
default['nfs']['config']['server_template'] = if node['platform_family'] == 'debian'
                                                '/etc/default/nfs-kernel-server'
                                              else
                                                '/etc/sysconfig/nfs'
                                              end

# idmap recipe attributes
default['nfs']['config']['idmap_template'] = '/etc/idmapd.conf'

# I don't think this gets pulled in as a unit file dependency on nfs-client.target
default['nfs']['service']['idmap'] = 'nfs-idmapd.service'

default['nfs']['idmap']['domain'] = node['domain']

# I'm assuming both Debian and Ubuntu use this FHS tree for var data
default['nfs']['idmap']['pipefs_directory'] = if node['platform_family'] == 'debian'
                                                '/run/rpc_pipefs'
                                              else
                                                '/var/lib/nfs/rpc_pipefs'
                                              end

# The nobody service user, and nogroup edge-case
default['nfs']['idmap']['user'] = 'nobody'
default['nfs']['idmap']['group'] = if node['platform_family'] == 'debian'
                                     'nogroup'
                                   else
                                     'nobody'
                                   end

# These are object refs to the default services, used as an iteration key in recipe.
# These are not the literal service names passed to the service resource.
# i.e. nfs.service.config, nfs.service.portmap, nfs.service.lock above
default['nfs']['client-services'] = if node['platform_family'] == 'debian'
                                      %w(config portmap lock)
                                    else
                                      %w(portmap lock)
                                    end

# Platforms that may no longer work?
case node['platform_family']
when 'freebsd'
  # Packages are installed by default
  default['nfs']['packages'] = []
  default['nfs']['config']['server_template'] = '/etc/rc.conf.d/nfsd'
  default['nfs']['config']['client_templates'] = %w(/etc/rc.conf.d/mountd)
  default['nfs']['service']['lock'] = 'lockd'
  default['nfs']['service']['server'] = 'nfsd'
  default['nfs']['threads'] = 24
  default['nfs']['mountd_flags'] = '-r'
  default['nfs']['server_flags'] = if node['nfs']['threads'] >= 0
                                     "-u -t -n #{node['nfs']['threads']}"
                                   else
                                     '-u -t'
                                   end
when 'suse'
  default['nfs']['packages'] = %w(nfs-client nfs-kernel-server rpcbind)
  default['nfs']['service']['lock'] = 'nfsserver'
  default['nfs']['service']['server'] = 'nfsserver'
  default['nfs']['config']['client_templates'] = %w(/etc/sysconfig/nfs)
end
