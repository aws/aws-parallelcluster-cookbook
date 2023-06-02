#!/bin/bash

echo "**** hooks POC pre-pre_converge"

[[ "${KITCHEN_DRIVER}" = "ec2" ]] || return
[ -n "${KITCHEN_INSTANCE_HOSTNAME}" ] || return

RESOURCE_NAME=ebs_volume_id_ebs_mount

KITCHEN_EBS_VOLUME_ID=$(cat "${KITCHEN_ROOT_DIR}/test/environments/kitchen.rb"  | sed -n -e "s/.*'${RESOURCE_NAME}\/${KITCHEN_PLATFORM_NAME}' => '\(.*\)',/\1/p")

echo "** Deleting EBS volume ${KITCHEN_EBS_VOLUME_ID}"

aws ec2 detach-volume --volume-id "${KITCHEN_EBS_VOLUME_ID}"

echo "** EBS volume ${KITCHEN_EBS_VOLUME_ID} detached"

aws ec2 delete-volume --volume-id "${KITCHEN_EBS_VOLUME_ID}"

echo "** EBS volume ${KITCHEN_EBS_VOLUME_ID} deleted"

