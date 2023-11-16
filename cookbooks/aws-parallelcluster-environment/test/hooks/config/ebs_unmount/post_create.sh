#!/bin/bash

echo "**** post_create"

[[ "${KITCHEN_DRIVER}" = "ec2" ]] || exit 0

RESOURCE_NAME=ebs_unmount-vol_array

echo "** Creating EBS volume..."

KITCHEN_EBS_VOLUME_ID=$(aws ec2 create-volume \
        --region "${KITCHEN_AWS_REGION}" \
        --availability-zone "${KITCHEN_AWS_REGION}${KITCHEN_AVAILABILITY_ZONE}" \
        --size 1 \
        --tag-specifications "ResourceType=volume,Tags=[{Key=Kitchen, Value=true},{Key=Platform, Value=${KITCHEN_PLATFORM_NAME}},{Key=ResourceName, Value=${RESOURCE_NAME}}]" \
        --query "VolumeId" --output text)

echo "** EBS volume created: ${KITCHEN_EBS_VOLUME_ID}"

sed -i.bak "s#'${RESOURCE_NAME}/${KITCHEN_PLATFORM_NAME}' => .*,#'${RESOURCE_NAME}/${KITCHEN_PLATFORM_NAME}' => %w(${KITCHEN_EBS_VOLUME_ID}),#" "${KITCHEN_ROOT_DIR}/test/environments/kitchen.rb"
