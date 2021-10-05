#!/bin/bash

# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

. /etc/parallelcluster/cfnconfig

LVM_VG_NAME="vg.01"
LVM_NAME="lv_ephemeral"
LVM_PATH="/dev/${LVM_VG_NAME}/${LVM_NAME}"
LVM_ACTIVE_STATE="a"
FS_TYPE="ext4"
MOUNT_OPTIONS="noatime,nodiratime"
# cfn_ephemeral_dir is set in the environment by cfnconfig sourcing
INPUT_MOUNTPOINT="${cfn_ephemeral_dir}"

function log {
  SCRIPT=$(basename "$0")
  MESSAGE="$1"
  echo "ParallelCluster - ${MESSAGE}"
}

function error_exit {
  log "[ERROR] $1"
  exit 1
}

function exit_noop {
  log "[INFO] $1"
  exit 0
}

function parameter_check {
  if [[ -z "${INPUT_MOUNTPOINT}" ]]; then
    exit_noop "Mount point not specified"
  fi
}

function set_imds_token {
  if [[ -z "${IMDS_TOKEN}" ]];then
    IMDS_TOKEN=$(curl --retry 3 --retry-delay 0 --fail -s -f -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 900" http://169.254.169.254/latest/api/token)
    if [[ "$?" -gt 0 ]] || [[ -z "${IMDS_TOKEN}" ]]; then
      error_exit "Could not get IMDSv2 token. Instance Metadata might have been disabled or this is not an EC2 instance"
    fi
  fi
}

function get_metadata {
    QUERY=$1
    local IMDS_OUTPUT
    IMDS_OUTPUT=$(curl --retry 3 --retry-delay 0 --fail -s -q -H "X-aws-ec2-metadata-token:${IMDS_TOKEN}" -f "http://169.254.169.254/latest/${QUERY}")
    echo -n "${IMDS_OUTPUT}"
}

function print_block_device_mapping {
  echo 'block-device-mapping: '
  DEVICE_MAPPING_LIST=$(get_metadata meta-data/block-device-mapping/)
  if [[ -n "${DEVICE_MAPPING_LIST}" ]]; then
    for DEVICE_MAPPING in ${DEVICE_MAPPING_LIST}; do
      echo -e '\t' "${DEVICE_MAPPING}: $(get_metadata meta-data/block-device-mapping/"${DEVICE_MAPPING}")"
    done
  else
    echo "NOT AVAILABLE"
  fi
}

function check_instance_store {
  if ls /dev/nvme* >& /dev/null; then
    IS_NVME=1
    MAPPINGS=$(realpath --relative-to=/dev/ -P /dev/disk/by-id/nvme*Instance_Storage* | grep -v "*Instance_Storage*" | uniq)
  else
    IS_NVME=0
    set_imds_token
    MAPPINGS=$(print_block_device_mapping | grep ephemeral | awk '{print $2}' | sed 's/sd/xvd/')
  fi

  NUM_DEVICES=0
  for MAPPING in ${MAPPINGS}; do
    umount "/dev/${MAPPING}" &>/dev/null
    STAT_COMMAND="stat -t /dev/${MAPPING}"
    if ${STAT_COMMAND} &>/dev/null; then
      DEVICES+=("/dev/${MAPPING}")
      NUM_DEVICES=$((NUM_DEVICES + 1))
    fi
  done

  if [[ "${NUM_DEVICES}" -gt 0 ]]; then
    log "This instance type has (${NUM_DEVICES}) device(s) for instance store: (${DEVICES[*]})"
  else
    exit_noop "This instance type doesn't have instance store"
  fi

  if [[ "${IS_NVME}" -eq 0 ]]; then
    log "This instance store may suffer first-write penalty unless initialized: please have a look at https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/disk-performance.html"
    # Initialization can take long time, even hours
    # for DEVICE in "${DEVICES[@]}"; do
    #  dd if=/dev/zero of="${DEVICE}" bs=1M
    # done
  fi
}

function create_lvm {
  log "Creating LVM (${LVM_PATH})"
  pvcreate -y "${DEVICES[@]}"
  vgcreate -y "${LVM_VG_NAME}" "${DEVICES[@]}"
  LVM_CREATE_COMMAND="lvcreate -y -i ${NUM_DEVICES} -I 64 -l 100%FREE -n ${LVM_NAME} ${LVM_VG_NAME}"
  if ! ${LVM_CREATE_COMMAND}; then
    error_exit "Failed to create LVM"
  else
    log "LVM (${LVM_PATH}) created successfully"
  fi
}

function check_lvm_exist {
  LVM_EXIST_COMMAND="lvs ${LVM_PATH} --nosuffix --noheadings -q"

  if ! ${LVM_EXIST_COMMAND} &>/dev/null; then
    log "LVM (${LVM_PATH}) does not exist"
    create_lvm
  else
    log "LVM (${LVM_PATH}) already exists"
  fi
}

function activate_lvm {
  LVM_STATE=$(lvs "${LVM_PATH}" --nosuffix --noheadings -o lv_attr | xargs | cut -c5)
  log "Found LVM (${LVM_PATH}) in state (${LVM_STATE})"

  if [[ "${LVM_STATE}" != "${LVM_ACTIVE_STATE}" ]]; then
    log "Activating LVM (${LVM_PATH})"
    LVM_ACTIVATE_COMMAND="lvchange -ay ${LVM_PATH}"
    if ! ${LVM_ACTIVATE_COMMAND}; then
      error_exit "Failed to activate LVM"
    else
      log "LVM (${LVM_PATH}) activated successfully"
    fi
  fi
}

function format_lvm {
  LVM_FS_TYPE=$(lsblk "${LVM_PATH}" --noheadings -o FSTYPE | xargs)
  log "Found LVM (${LVM_PATH}) FS type (${LVM_FS_TYPE})"

  if [[ "${LVM_FS_TYPE}" != "${FS_TYPE}" ]]; then
    log "Formatting LVM (${LVM_PATH}) with FS type (${FS_TYPE})"
    LVM_FORMAT_COMMAND="mkfs -t ${FS_TYPE} ${LVM_PATH}"
    if ! ${LVM_FORMAT_COMMAND}; then
      error_exit "Failed to format LVM"
    else
      log "LVM (${LVM_PATH}) formatted successfully"
    fi
    sync
    sleep 1
  else
    log "LVM (${LVM_PATH}) already formatted with FS type (${LVM_FS_TYPE})"
  fi
}

function mount_lvm {
  LVM_MOUNTPOINT=$(lsblk "${LVM_PATH}" -o MOUNTPOINT --noheadings | xargs)

  if [[ -z ${LVM_MOUNTPOINT} ]]; then
    log "LVM (${LVM_PATH}) not mounted, mounting on (${INPUT_MOUNTPOINT})"
    # create mount
    mkdir -p "${INPUT_MOUNTPOINT}"
    LVM_MOUNT_COMMAND="mount -v -t ${FS_TYPE} -o ${MOUNT_OPTIONS} ${LVM_PATH} ${INPUT_MOUNTPOINT}"
    if ! ${LVM_MOUNT_COMMAND}; then
      error_exit "Failed to mount LVM"
    else
      log "LVM (${LVM_PATH}) mounted successfully"
    fi
    # set mount permission
    chmod 1777 "${INPUT_MOUNTPOINT}"
  else
    log "LVM (${LVM_PATH}) already mounted on (${LVM_MOUNTPOINT})"
  fi
}

function main {
  parameter_check
  check_instance_store
  check_lvm_exist
  activate_lvm
  format_lvm
  mount_lvm
}

main
