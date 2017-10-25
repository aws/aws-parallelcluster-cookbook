#!/bin/bash

set -x

# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

. /etc/cfncluster/cfnconfig

# Error exit function
function error_exit () {
  script=`basename $0`
  echo "cfncluster: $script - $1"
  logger -t cfncluster "$script - $1"
  exit 1
}


# LVM stripe, format, mount ephemeral drives
function setup_ephemeral_drives () {
  RC=0
  mkdir -p ${cfn_ephemeral_dir} || RC=1
  chmod 1777 ${cfn_ephemeral_dir} || RC=1
  if ls /dev/nvme* >& /dev/null; then
    MAPPING=$(ls /dev/disk/by-id/ |& grep Instance_Storage | grep nvme)
  else
    MAPPING=$(/usr/bin/ec2-metadata -b | grep ephemeral | awk '{print $2}' | sed 's/sd/xvd/')
  fi
  NUM_DEVS=0
  for m in $MAPPING; do
    umount /dev/${m} >/dev/null 2>&1
    stat -t /dev/${m} >/dev/null 2>&1
    check=$?
    if [ ${check} -eq 0 ]; then
      DEVS="${m} $DEVS"
      let NUM_DEVS++
    fi
  done
  if [ $NUM_DEVS -gt 0 ]; then
    for d in $DEVS; do
      d=/dev/${d}
      dd if=/dev/zero of=${d} bs=32k count=1 || RC=1
      parted -s ${d} mklabel msdos || RC=1
      parted -s ${d} || RC=1
      parted -s -a optimal ${d} mkpart primary 1MB 100% || RC=1
      parted -s ${d} set 1 lvm on || RC=1
      PARTITIONS="${d}1 $PARTITIONS"
    done
    if [ $RC -ne 0 ]; then
      error_exit "Failed to detect and/or partition ephemeral devices."
    fi

    # sleep 10 seconds to let partitions settle (bug?)
    sleep 10

    # Setup LVM
    RC=0
    pvcreate $PARTITIONS || RC=1
    vgcreate vg.01 $PARTITIONS || RC=1
    lvcreate -i $NUM_DEVS -I 64 -l 100%FREE -n lv_ephemeral vg.01 || RC=1
    if [ "$cfn_encrypted_ephemeral" == "true" ]; then
      mkfs -q /dev/ram1 1024 || RC=1
      mkdir -p /root/keystore || RC=1
      mount /dev/ram1 /root/keystore || RC=1
      dd if=/dev/urandom of=/root/keystore/keyfile bs=1024 count=4 || RC=1
      chmod 0400 /root/keystore/keyfile || RC=1
      cryptsetup -q luksFormat /dev/vg.01/lv_ephemeral /root/keystore/keyfile || RC=1
      cryptsetup -d /root/keystore/keyfile luksOpen /dev/vg.01/lv_ephemeral ephemeral_luks || RC=1
      mkfs.ext4 /dev/mapper/ephemeral_luks || RC=1
      mount -v -t ext4 -o noatime,nodiratime /dev/mapper/ephemeral_luks ${cfn_ephemeral_dir} || RC=1
    else
      mkfs.ext4 /dev/vg.01/lv_ephemeral || RC=1
      echo "/dev/vg.01/lv_ephemeral ${cfn_ephemeral_dir} ext4 noatime,nodiratime 0 0" >> /etc/fstab || RC=1
      mount -v ${cfn_ephemeral_dir} || RC=1
    fi
  fi
  chmod 1777 ${cfn_ephemeral_dir} || RC=1
  if [ $RC -ne 0 ]; then
    error_exit "Failed to create LVM stripe and/or format ephemeral volume."
  fi
}

setup_ephemeral_drives