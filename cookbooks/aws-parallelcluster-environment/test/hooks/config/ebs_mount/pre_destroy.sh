#!/bin/bash

echo "**** pre_destroy"

[[ "${KITCHEN_DRIVER}" = "ec2" ]] || exit 0
[ -n "${KITCHEN_INSTANCE_HOSTNAME}" ] || exit 0

RESOURCE_NAME=ebs_mount-vol_array

KITCHEN_EBS_VOLUME_ID=$(cat "${KITCHEN_ROOT_DIR}/test/environments/kitchen.rb" | sed -n -e "s/.*'${RESOURCE_NAME}\/${KITCHEN_PLATFORM_NAME}' => %w(\(.*\)),/\1/p")
[ -z "${KITCHEN_EBS_VOLUME_ID}" ] && echo "Volume not available. Skipping pre_destroy hook." && exit 0

echo "** Deleting EBS volume ${KITCHEN_EBS_VOLUME_ID}"

aws ec2 detach-volume --volume-id "${KITCHEN_EBS_VOLUME_ID}" --region "${KITCHEN_AWS_REGION}"
echo "** EBS volume ${KITCHEN_EBS_VOLUME_ID} detached"

aws ec2 wait volume-available --volume-ids ${KITCHEN_EBS_VOLUME_ID} --region "${KITCHEN_AWS_REGION}"

aws ec2 delete-volume --volume-id "${KITCHEN_EBS_VOLUME_ID}" --region "${KITCHEN_AWS_REGION}"
echo "** EBS volumes ${KITCHEN_EBS_VOLUME_ID} deleted"
