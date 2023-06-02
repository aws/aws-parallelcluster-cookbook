# sed -i.bak "s#'ebs_volume_id/alinux2' => '<put your id here>',#" test/environments/kitchen.rb

name 'newenv'
default_attributes 'kitchen_hooks' => {
  'ebs_volume_id_ebs_mount/alinux2' => 'vol-0275f6b70934850af',
  'ebs_volume_id_ebs_mount/rhel8' => 'vol-05bd421bfd23c1c8d',
  'ebs_volume_id_ebs_mount/centos7' => 'vol-03cdd20a7b89eccf0',
  'ebs_volume_id_ebs_mount/ubuntu1804' => 'vol-0d51f9fca3d80b4fb',
  'ebs_volume_id_ebs_mount/ubuntu2004' => 'vol-06835966c9152c876',
  'ebs_volume_id_ebs_mount/ubuntu2204' => 'vol-0ce05a2e6b48bfdf4',
}
