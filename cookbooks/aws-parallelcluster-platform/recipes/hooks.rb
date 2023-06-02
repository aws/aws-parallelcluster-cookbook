log "Environment #{node.environment}"

resource_name = 'ebs_volume_id_ebs_mount'
platform_name = node['cluster']['base_os']
key = "#{resource_name}/#{platform_name}"

log "volume #{node['kitchen_hooks'][key]}"
