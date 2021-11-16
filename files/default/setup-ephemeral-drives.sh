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

. /etc/parallelcluster/cfnconfig

# Error exit function
function error_exit () {
  script=`basename $0`
  echo "parallelcluster: $script - $1"
  logger -t parallelcluster "$script - $1"
  exit 1
}

function exec_command() {
  _command_output=$($@ 2>&1)
  _exit_code=$?
  echo "${_command_output}" | grep -vi "you should reboot now" >& /dev/null
  _grep_exit_code=$?

  # Do not set RC=1 if error says that changes have been written but a reboot is required to inform the kernel
  [[ ${_exit_code} -ne 0 && ${_grep_exit_code} -eq 0 ]] && RC=1
}

function set_imds_token(){
  if [ -z "${IMDS_TOKEN}" ];then
    IMDS_TOKEN=$(curl --retry 20 --retry-delay 1 --fail -s -f -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 900" http://169.254.169.254/latest/api/token)
    if [ "${?}" -gt 0 ] || [ -z "${IMDS_TOKEN}" ]; then
      echo '[ERROR] Could not get IMDSv2 token. Instance Metadata might have been disabled or this is not an EC2 instance.'
      exit 1
    fi
  fi
}

# param1 = query
function get_meta() {
    local imds_out=$(curl --retry 20 --retry-delay 1 --fail -s -q -H "X-aws-ec2-metadata-token:${IMDS_TOKEN}" -f http://169.254.169.254/latest/${1})
    echo -n "${imds_out}"
}

#print block-device-mapping
function print_block-device-mapping(){
  echo 'block-device-mapping: '
  x=$(get_meta meta-data/block-device-mapping/)
  if [ -n "${x}" ]; then
    for i in $x; do
      echo -e '\t' $i: $(get_meta meta-data/block-device-mapping/$i)
    done
  else
    echo not available
  fi
}

# LVM stripe, format, mount ephemeral drives
function setup_ephemeral_drives () {
  RC=0
  mkdir -p ${cfn_ephemeral_dir} || RC=1
  chmod 1777 ${cfn_ephemeral_dir} || RC=1
  if ls /dev/nvme* >& /dev/null; then
    IS_NVME=1
    MAPPING=$(realpath --relative-to=/dev/ -P  /dev/disk/by-id/nvme*Instance_Storage* | uniq)
  else
    IS_NVME=0
    set_imds_token
    MAPPING=$(print_block-device-mapping | grep ephemeral | awk '{print $2}' | sed 's/sd/xvd/')
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
      exec_command "parted -s ${d} mklabel gpt"
      exec_command "parted -s ${d}"
      exec_command "parted -s -a optimal ${d} mkpart primary 1MB 100%"
      partprobe ${d}
      exec_command "parted -s ${d} set 1 lvm on"
      if [ $IS_NVME -eq 1 ]; then
        PARTITIONS="${d}p1 $PARTITIONS"
      else
        PARTITIONS="${d}1 $PARTITIONS"
      fi
    done
    if [ $RC -ne 0 ]; then
      error_exit "Failed to detect and/or partition ephemeral devices."
    fi

    # sleep 10 seconds to let partitions settle (bug?)
    sleep 10

    # Setup LVM
    RC=0
    pvcreate -y $PARTITIONS || RC=1
    vgcreate -y vg.01 $PARTITIONS || RC=1
    lvcreate -y -i $NUM_DEVS -I 64 -l 100%FREE -n lv_ephemeral vg.01 || RC=1
    if [ "$cfn_encrypted_ephemeral" == "true" ]; then
      modprobe brd || RC=1
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
