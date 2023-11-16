return if on_docker?

keys_dir = "#{node['cluster']['shared_dir_login_nodes']}"
script_name = "keys-manager.sh"
script_dir = "#{keys_dir}/scripts"

directory keys_dir
directory script_dir

cookbook_file "#{script_dir}/#{script_name}" do
  source 'login_nodes/keys-manager.sh'
  owner 'root'
  group 'root'
  mode '0744'
  action :create_if_missing
end

execute 'Initialize Login Nodes keys' do
  command "bash #{script_dir}/#{script_name} --create --folder-path #{keys_dir}"
  user 'root'
end
