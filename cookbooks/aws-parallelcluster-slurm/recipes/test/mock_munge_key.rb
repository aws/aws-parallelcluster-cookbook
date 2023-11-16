munge_dirs = %W(#{node['cluster']['shared_dir']}/.munge #{node['cluster']['shared_dir_login']}/.munge)

munge_dirs.each do |munge_dir|
  directory munge_dir do
    mode '0700'
  end

  bash "mock_munge_key" do
    user 'root'
    group 'root'
    code <<-MOCK_KEY
      set -e
      munge_directory=#{munge_dir}
      encoded_key='lWXJDxgGhJxIVqLdbaycUICm12u0gHtcDFslGGxJlyLoVIQJFuskDfkK8wjvQfhT5pkeyuxA+vjgg9R+E+ftPVTsVLHaf4bx3RmEfe30bZo79Yg+GhTRJRzV401/VaTlVEGFwMcJhmVKrXX/MbfnIdMwWNgCL8swUELbFOI4CG0='
      decoded_key=$(echo $encoded_key | base64 -d)
      echo "${decoded_key}" > ${munge_directory}/.munge.key
      chmod 0600 ${munge_directory}/.munge.key
    MOCK_KEY
  end
end
