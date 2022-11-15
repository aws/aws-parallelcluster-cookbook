
cookbook_file "#{node['cluster']['scripts_dir']}/write_chef_error_handler.rb" do
  source 'event_handler/write_chef_error_handler.rb'
  owner 'root'
  group 'root'
  mode '0755'
end

chef_handler 'WriteChefError::WriteChefError' do
  source "#{node['cluster']['scripts_dir']}/write_chef_error_handler.rb"
  supports :exception => true
  action :enable
end
