#!/bin/bash

echo "**** pre_destroy"

[[ "${KITCHEN_DRIVER}" = "ec2" ]] || exit 0
[ -n "${KITCHEN_INSTANCE_HOSTNAME}" ] || exit 0

RESOURCE_NAME=raid_mount-raid_vol_array

KITCHEN_EBS_VOLUME_ID1=$(cat "${KITCHEN_ROOT_DIR}/test/environments/kitchen.rb" | sed -n -e "s/.*'${RESOURCE_NAME}\/${KITCHEN_PLATFORM_NAME}' => %w(\(.*\) \(.*\)),/\1/p")
KITCHEN_EBS_VOLUME_ID2=$(cat "${KITCHEN_ROOT_DIR}/test/environments/kitchen.rb" | sed -n -e "s/.*'${RESOURCE_NAME}\/${KITCHEN_PLATFORM_NAME}' => %w(\(.*\) \(.*\)),/\2/p")

echo "** Deleting EBS volumes ${KITCHEN_EBS_VOLUME_ID1} ${KITCHEN_EBS_VOLUME_ID2}"

aws ec2 detach-volume --volume-id "${KITCHEN_EBS_VOLUME_ID1}" --region "${KITCHEN_AWS_REGION}"
echo "** EBS volume ${KITCHEN_EBS_VOLUME_ID1} detached"
aws ec2 detach-volume --volume-id "${KITCHEN_EBS_VOLUME_ID2}" --region "${KITCHEN_AWS_REGION}"
echo "** EBS volume ${KITCHEN_EBS_VOLUME_ID2} detached"

aws ec2 wait volume-available --volume-ids ${KITCHEN_EBS_VOLUME_ID1} ${KITCHEN_EBS_VOLUME_ID2} --region "${KITCHEN_AWS_REGION}"

aws ec2 delete-volume --volume-id "${KITCHEN_EBS_VOLUME_ID1}" --region "${KITCHEN_AWS_REGION}"
aws ec2 delete-volume --volume-id "${KITCHEN_EBS_VOLUME_ID2}" --region "${KITCHEN_AWS_REGION}"
echo "** EBS volumes ${KITCHEN_EBS_VOLUME_ID1} and ${KITCHEN_EBS_VOLUME_ID2} deleted"
