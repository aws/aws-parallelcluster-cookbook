
template 'bad_file.txt' do
  begin
  source 'shared_storages/bad_file.txt.erb'
  mode '0644'
  rescue
  end
end

