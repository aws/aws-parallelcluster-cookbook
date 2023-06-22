# In order to share values with kitchen recipes running remotely, attribute values must be set in this file.
# For every value to pass and for every OS, add a line to this file:
#   '<suite_name>-<variable_name>/<platform>' => 'placeholder'
# For instance: 'ebs_mount-vol_array/alinux2' => 'placeholder'.
name 'kitchen'
default_attributes 'kitchen_hooks' => {
  'ebs_mount-vol_array/alinux2' => '',
  'ebs_mount-vol_array/rhel8' => '',
  'ebs_mount-vol_array/centos7' => '',
  'ebs_mount-vol_array/ubuntu1804' => '',
  'ebs_mount-vol_array/ubuntu2004' => '',
  'ebs_mount-vol_array/ubuntu2204' => '',
  'ebs_unmount-vol_array/alinux2' => '',
  'ebs_unmount-vol_array/rhel8' => '',
  'ebs_unmount-vol_array/centos7' => '',
  'ebs_unmount-vol_array/ubuntu1804' => '',
  'ebs_unmount-vol_array/ubuntu2004' => '',
  'ebs_unmount-vol_array/ubuntu2204' => '',
  'raid_mount-raid_vol_array/alinux2' => '',
  'raid_mount-raid_vol_array/rhel8' => '',
  'raid_mount-raid_vol_array/centos7' => '',
  'raid_mount-raid_vol_array/ubuntu1804' => '',
  'raid_mount-raid_vol_array/ubuntu2004' => '',
  'raid_mount-raid_vol_array/ubuntu2204' => '',
  'raid_unmount-raid_vol_array/alinux2' => '',
  'raid_unmount-raid_vol_array/rhel8' => '',
  'raid_unmount-raid_vol_array/centos7' => '',
  'raid_unmount-raid_vol_array/ubuntu1804' => '',
  'raid_unmount-raid_vol_array/ubuntu2004' => '',
  'raid_unmount-raid_vol_array/ubuntu2204' => '',
  'lustre_mount-fsx_fs_id_array' => ["fs-0ab11b3ade43091fe"],
  'lustre_mount-fsx_dns_name_array' => ["fs-0ab11b3ade43091fe.fsx.us-west-2.amazonaws.com"],
  'lustre_mount-fsx_mount_name_array' => ["qz5b7bev"],
  'lustre_unmount-fsx_fs_id_array' => '',
  'lustre_unmount-fsx_dns_name_array' => '',
  'lustre_unmount-fsx_mount_name_array' => '',
}
