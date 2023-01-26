# RedHat 8 common attributes shared between multiple cookbooks

return unless platform?('redhat') && node['platform_version'].to_i == 8

# Modulefile Directory
default['cluster']['modulefile_dir'] = "/usr/share/Modules/modulefiles"
# MODULESHOME
default['cluster']['moduleshome'] = "/usr/share/Modules"
default['cluster']['modulepath_config_file'] = "#{node['cluster']['moduleshome']}/init/.modulespath"

default['cluster']['chrony']['service'] = "chronyd"
