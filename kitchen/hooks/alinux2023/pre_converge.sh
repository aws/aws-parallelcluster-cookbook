#!/bin/bash

if [ -n "${KITCHEN_INSTANCE_HOSTNAME}" ]; then
    export KITCHEN_EC2_USER='ec2-user'
    echo "Install libxcrypt-compat package by using SSH key: ${KITCHEN_SSH_KEY_PATH}"

    KITCHEN_EC2_INSTANCE_ID=$(ssh -o StrictHostKeyChecking=no -i "${KITCHEN_SSH_KEY_PATH}" \
      "${KITCHEN_EC2_USER}@${KITCHEN_INSTANCE_HOSTNAME}" 'sudo yum install -y libxcrypt-compat')
fi
