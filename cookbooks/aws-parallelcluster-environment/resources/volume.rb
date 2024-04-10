provides :volume
unified_mode true

property :shared_dir, String, required: %i(mount export unmount)
property :device, String, required: %i(mount)
property :fstype, String, required: %i(mount)
property :options, [Array, String], required: %i(mount)
property :device_type, [String, Symbol], default: :device
property :volume_id, String, required: %i(attach detach)

action :attach do
  volume_id = new_resource.volume_id.strip
  dev_path = "/dev/disk/by-ebs-volumeid/#{volume_id}"

  execute "attach_volume_#{volume_id}" do
    command "#{cookbook_virtualenv_path}/bin/python /usr/local/sbin/manageVolume.py --volume-id #{volume_id} --attach"
    creates dev_path
  end

  # wait for the drive to attach, before making a filesystem
  ruby_block "sleeping_for_volume_#{volume_id}" do
    block do
      wait_for_block_dev(dev_path)
    end
    action :nothing
    subscribes :run, "execute[attach_volume_#{volume_id}]", :immediately
  end
end

action :detach do
  volume_id = new_resource.volume_id.strip
  # Detach EBS volume
  execute "detach_volume_#{volume_id}" do
    command "#{cookbook_virtualenv_path}/bin/python /usr/local/sbin/manageVolume.py --volume-id #{volume_id} --detach"
  end
end

action :mount do
  shared_dir = format_directory(new_resource.shared_dir)

  # Create the shared directories
  directory shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
    recursive true
    action :create
  end

  # Add volume to /etc/fstab
  mount "mount #{shared_dir}" do
    mount_point shared_dir
    device(new_resource.device)
    fstype(new_resource.fstype)
    device_type new_resource.device_type
    options new_resource.options
    pass 0
    action :mount
    retries new_resource.retries
    retry_delay new_resource.retry_delay
    not_if "mount | grep ' #{shared_dir} '"
  end

  mount "enable #{shared_dir}" do
    mount_point shared_dir
    device(new_resource.device)
    fstype(new_resource.fstype)
    device_type new_resource.device_type
    options new_resource.options
    pass 0
    action :enable
    retries new_resource.retries
    retry_delay new_resource.retry_delay
    only_if "mount | grep ' #{shared_dir} '"
  end

  # Make sure shared directory permissions are correct
  directory shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
  end
end

action :export do
  shared_dir = format_directory(new_resource.shared_dir)

  nfs_export shared_dir do
    network get_vpc_cidr_list
    writeable true
    options ['no_root_squash']
  end
end

action :unmount do
  shared_dir = format_directory(new_resource.shared_dir)

  # TODO: can we use mount resource to unmount and disable (see raid)
  execute "unmount volume #{shared_dir}" do
    command "umount -fl #{shared_dir}"
    retries 10
    retry_delay 6
    timeout 60
    only_if "mount | grep ' #{shared_dir} '"
  end

  # remove volume from fstab
  delete_lines "remove volume #{shared_dir} from /etc/fstab" do
    path "/etc/fstab"
    pattern " #{shared_dir} "
  end

  # Delete the shared directories
  directory shared_dir do
    recursive false
    action :delete
    only_if { Dir.exist?(shared_dir) && Dir.empty?(shared_dir) }
  end
end

action :unexport do
  shared_dir = format_directory(new_resource.shared_dir)

  # unexport the volume
  delete_lines "remove volume #{shared_dir} from /etc/exports" do
    path "/etc/exports"
    pattern "^#{shared_dir} *"
  end

  execute "unexport volume" do
    command "exportfs -ra"
    default_env true
  end
end
