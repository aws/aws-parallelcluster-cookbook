#!/bin/bash

export KITCHEN_HOOK=$1
export KITCHEN_ROOT_DIR=$2

[[ "${KITCHEN_INSTANCE_HOSTNAME}" = "" ]] && exit 0

echo "*** Run ${KITCHEN_HOOK} for suite ${KITCHEN_SUITE_NAME} on host ${KITCHEN_INSTANCE_HOSTNAME}"

THIS_DIR=$(dirname "$0")
SCRIPT="${THIS_DIR}/${KITCHEN_SUITE_NAME}/${KITCHEN_HOOK}.sh"

if [ -e "${SCRIPT}" ]; then
  if [ "${KITCHEN_DRIVER}" = "ec2" ]; then
    echo "*** Retrieve EC2 instance id using key ${KITCHEN_SSH_KEY_PATH}"

    case $KITCHEN_PLATFORM_NAME in
      alinux*|redhat* ) export KITCHEN_EC2_USER='ec2-user';;
      centos*         ) export KITCHEN_EC2_USER='centos';;
      ubuntu*         ) export KITCHEN_EC2_USER='ubuntu';;
    esac

    KITCHEN_EC2_INSTANCE_ID=$(ssh -o StrictHostKeyChecking=no -i "${KITCHEN_SSH_KEY_PATH}" \
      "${KITCHEN_EC2_USER}@${KITCHEN_INSTANCE_HOSTNAME}" '
      TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600") \
      && curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id
    ')

    echo "EC2 instance id: ${KITCHEN_EC2_INSTANCE_ID}"

    export KITCHEN_EC2_INSTANCE_ID
  fi

  # shellcheck disable=SC1090
  source "${SCRIPT}"

else
  echo "*** Hook ${KITCHEN_HOOK} undefined for ${KITCHEN_SUITE_NAME}"
fi
