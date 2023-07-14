return if on_docker?

keys_manager_script_dir = "#{node['cluster']['scripts_dir']}/login_nodes"
keys_dir = "#{node['cluster']['shared_dir_login_nodes']}"
script_name = "keys-manager.sh"

directory keys_dir

directory keys_manager_script_dir do
  owner 'root'
  group 'root'
  mode '0744'
  recursive true
end

cookbook_file "#{keys_manager_script_dir}/#{script_name}" do
  source 'login_nodes/keys-manager.sh'
  owner 'root'
  group 'root'
  mode '0744'
  action :create_if_missing
end

nfs_export keys_manager_script_dir do
  network '127.0.0.1/32'
  writeable true
  options ['no_root_squash']
end

execute 'Initialize Login Nodes keys' do
  command "bash #{keys_manager_script_dir}/#{script_name} --create --folder-path #{keys_dir}"
  user 'root'
end
