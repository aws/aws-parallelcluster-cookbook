property :stunnel_version, String, default: lazy { node['cluster']['stunnel']['version'] }
property :stunnel_checksum, String, default: lazy { node['cluster']['stunnel']['sha256'] }

unified_mode true
default_action :setup
