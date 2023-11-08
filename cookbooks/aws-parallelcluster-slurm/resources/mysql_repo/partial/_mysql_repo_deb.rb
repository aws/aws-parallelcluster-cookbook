unified_mode true
default_action :add

action :add do
  remote_file local_path do
    source repository_package
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  ruby_block "Validate Repository Definition Checksum" do
    block do
      validate_file_md5_hash(local_path, md5_signature)
    end
    not_if { ::File.exist?(local_path) }
  end

  dpkg_package repository_name do
    source local_path
  end

  apt_update 'update' do
    action :update
    retries 3
    retry_delay 5
  end
end

def repository_name
  'MySQL Repository'
end

def repository_package
  "https://dev.mysql.com/get/#{file_name}"
end

def local_path
  "/tmp/#{file_name}"
end
