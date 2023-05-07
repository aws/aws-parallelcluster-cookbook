# aws-parallelcluster-install attributes

# Default gc_thresh values for performance at scale
default['cluster']['sysctl']['ipv4']['gc_thresh1'] = 0
default['cluster']['sysctl']['ipv4']['gc_thresh2'] = 15_360
default['cluster']['sysctl']['ipv4']['gc_thresh3'] = 16_384

# Intel MPI
default['conditions']['intel_mpi_supported'] = !arm_instance?
default['cluster']['intelmpi']['version'] = '2021.9.0'
default['cluster']['intelmpi']['full_version'] = "#{node['cluster']['intelmpi']['version']}.43482"
default['cluster']['intelmpi']['modulefile'] = "/opt/intel/mpi/#{node['cluster']['intelmpi']['version']}/modulefiles/mpi"
default['cluster']['intelmpi']['qt_version'] = '6.4.2'
