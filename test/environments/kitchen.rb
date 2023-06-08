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
}
