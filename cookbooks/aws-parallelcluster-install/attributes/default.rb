# aws-parallelcluster-install attributes

# stunnel
default['cluster']['stunnel']['version'] = '5.67'
default['cluster']['stunnel']['url'] = lazy { "#{node['cluster']['artifacts_s3_url']}/stunnel/stunnel-#{node['cluster']['stunnel']['version']}.tar.gz" }
default['cluster']['stunnel']['sha256'] = '3086939ee6407516c59b0ba3fbf555338f9d52f459bcab6337c0f00e91ea8456'
default['cluster']['stunnel']['tarball_path'] = "#{node['cluster']['sources_dir']}/stunnel-#{node['cluster']['stunnel']['version']}.tar.gz"

# ArmPL
default['conditions']['arm_pl_supported'] = arm_instance?
