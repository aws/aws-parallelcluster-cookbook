munge_dirs = %W(#{node['cluster']['shared_dir']}/.munge #{node['cluster']['shared_dir_login']}/.munge)

munge_dirs.each do |munge_dir|
  directory munge_dir do
    mode '0700'
  end

  file "#{munge_dir}/.munge.key" do
    content 'munge-key'
    owner node['cluster']['munge']['user']
    group node['cluster']['munge']['group']
  end
end
