# Check if recipes are executed during kitchen tests.
def kitchen_test?
  node['kitchen']
end

def kitchen_root_path
  '/tmp/kitchen'
end

def kitchen_data_path
  "#{kitchen_root_path}/data"
end

def kitchen_cluster_config_path
  "#{kitchen_data_path}/cluster-config.yml"
end

def kitchen_instance_types_data_path
  "#{kitchen_data_path}/instance-types-data.json"
end
