#!/bin/bash

export KITCHEN_HOOK=$1
KITCHEN_ROOT_DIR=$(readlink -f $2)
export KITCHEN_ROOT_DIR
THIS_DIR=$(dirname "$0")

# Run OS specific hooks from kitchen/hooks folder
SCRIPT="${THIS_DIR}/hooks/${KITCHEN_PLATFORM_NAME}/${KITCHEN_HOOK}.sh"
if [ -e "${SCRIPT}" ]; then

  echo "*** Run ${KITCHEN_HOOK} on host ${KITCHEN_INSTANCE_HOSTNAME}"
  echo "**** Script: ${SCRIPT}"
  # shellcheck disable=SC1090
  source "${SCRIPT}"
fi

# Run test specific hooks from cookbooks/aws-parallelcluster-*/test/hooks folder
SCRIPT="${THIS_DIR}/../${KITCHEN_COOKBOOK_PATH}/test/hooks/${KITCHEN_PHASE}/${KITCHEN_SUITE_NAME}/${KITCHEN_HOOK}.sh"
if [ -e "${SCRIPT}" ]; then
  echo "*** Run ${KITCHEN_HOOK} for cookbook ${KITCHEN_COOKBOOK_PATH} suite ${KITCHEN_SUITE_NAME} on host ${KITCHEN_INSTANCE_HOSTNAME}"
  echo "**** Script: ${SCRIPT}"

  if [ "${KITCHEN_DRIVER}" = "ec2" ]; then

    if [ -n "${KITCHEN_INSTANCE_HOSTNAME}" ]; then
      case ${KITCHEN_PLATFORM_NAME} in
        alinux*|redhat* ) export KITCHEN_EC2_USER='ec2-user';;
        rocky*          ) export KITCHEN_EC2_USER='rocky';;
        centos*         ) export KITCHEN_EC2_USER='centos';;
        ubuntu*         ) export KITCHEN_EC2_USER='ubuntu';;
      esac
      echo "Retrieve EC2 instance id using key ${KITCHEN_SSH_KEY_PATH}"

      KITCHEN_EC2_INSTANCE_ID=$(ssh -o StrictHostKeyChecking=no -i "${KITCHEN_SSH_KEY_PATH}" \
        "${KITCHEN_EC2_USER}@${KITCHEN_INSTANCE_HOSTNAME}" '
        TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600") \
        && curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id
      ')
      echo "Install libxcrypt-compat dmidecode package by using SSH key: ${KITCHEN_SSH_KEY_PATH}"
      
      ssh -o StrictHostKeyChecking=no -i "${KITCHEN_SSH_KEY_PATH}" \
      "${KITCHEN_EC2_USER}@${KITCHEN_INSTANCE_HOSTNAME}" 'sudo yum install -y libxcrypt-compat dmidecode'

      [ -n "${KITCHEN_EC2_INSTANCE_ID}" ] && echo "EC2 instance id: ${KITCHEN_EC2_INSTANCE_ID}" || echo "Unable to retrieve instance id."
      export KITCHEN_EC2_INSTANCE_ID
    fi
  fi

  # shellcheck disable=SC1090
  source "${SCRIPT}"

else
  echo "*** Hook ${KITCHEN_HOOK} undefined for ${KITCHEN_SUITE_NAME}"
fi
