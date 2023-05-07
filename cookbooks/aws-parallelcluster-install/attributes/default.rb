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

# stunnel
default['cluster']['stunnel']['version'] = '5.67'
default['cluster']['stunnel']['url'] = lazy { "#{node['cluster']['artifacts_s3_url']}/stunnel/stunnel-#{node['cluster']['stunnel']['version']}.tar.gz" }
default['cluster']['stunnel']['sha256'] = '3086939ee6407516c59b0ba3fbf555338f9d52f459bcab6337c0f00e91ea8456'
default['cluster']['stunnel']['tarball_path'] = "#{node['cluster']['sources_dir']}/stunnel-#{node['cluster']['stunnel']['version']}.tar.gz"
