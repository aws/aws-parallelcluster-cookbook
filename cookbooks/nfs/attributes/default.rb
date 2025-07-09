#
# Cookbook:: nfs
# Attributes:: default
#
# Copyright:: 2011, Eric G. Wolfe
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
default['nfs']['packages'] = if platform_family?('debian')
                               %w(nfs-common rpcbind)
                             else
                               %w(nfs-utils rpcbind)
                             end

# Let systemd demand rpcbind
default['nfs']['service']['portmap'] = 'nfs-client.target'
default['nfs']['service']['statd'] = 'rpc-statd.service'
default['nfs']['service']['lock'] = 'nfs-client.target'

default['nfs']['service']['server'] = if platform_family?('debian')
                                        'nfs-kernel-server.service'
                                      else
                                        'nfs-server.service'
                                      end

# Client config defaults
default['nfs']['config']['client_templates'] =
  if platform_family?('debian')
    if platform?('ubuntu') && node['platform_version'].to_f >= 22.04
      %w(/etc/nfs.conf)
    else
      %w(/etc/default/nfs-common)
    end
  elsif platform_family?('rhel') && node['platform_version'].to_i >= 8
    %w(/etc/nfs.conf)
  elsif platform_family?('fedora')
    %w(/etc/nfs.conf)
  else
    %w(/etc/sysconfig/nfs)
  end

# Sever config defaults
default['nfs']['config']['server_template'] =
  if platform_family?('debian')
    if platform?('ubuntu') && node['platform_version'].to_f >= 22.04
      '/etc/nfs.conf'
    else
      '/etc/default/nfs-kernel-server'
    end
  elsif platform_family?('rhel') && node['platform_version'].to_i >= 8
    '/etc/nfs.conf'
  elsif platform_family?('fedora')
    '/etc/nfs.conf'
  else
    '/etc/sysconfig/nfs'
  end

# idmap recipe attributes
default['nfs']['config']['idmap_template'] = '/etc/idmapd.conf'

# I don't think this gets pulled in as a unit file dependency on nfs-client.target
default['nfs']['service']['idmap'] = 'nfs-idmapd.service'

default['nfs']['idmap']['domain'] = node['domain']

# I'm assuming both Debian and Ubuntu use this FHS tree for var data
default['nfs']['idmap']['pipefs_directory'] = if platform_family?('debian')
                                                '/run/rpc_pipefs'
                                              else
                                                '/var/lib/nfs/rpc_pipefs'
                                              end

# The nobody service user, and nogroup edge-case
default['nfs']['idmap']['user'] = 'nobody'
default['nfs']['idmap']['group'] = if platform_family?('debian')
                                     'nogroup'
                                   else
                                     'nobody'
                                   end

# These are object refs to the default services, used as an iteration key in recipe.
# These are not the literal service names passed to the service resource.
# i.e. nfs.service.portmap, nfs.service.lock above
default['nfs']['client-services'] = %w(portmap statd lock)

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
