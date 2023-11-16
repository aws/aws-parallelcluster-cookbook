#!/bin/bash

echo "**** post_create"

[[ "${KITCHEN_DRIVER}" = "ec2" ]] || return

RESOURCE_NAME=raid_unmount-raid_vol_array

echo "** Creating 2 EBS volumes..."

KITCHEN_EBS_VOLUME_ID1=$(aws ec2 create-volume \
        --region "${KITCHEN_AWS_REGION}" \
        --availability-zone "${KITCHEN_AWS_REGION}${KITCHEN_AVAILABILITY_ZONE}" \
        --size 1 \
        --tag-specifications "ResourceType=volume,Tags=[{Key=Kitchen, Value=true},{Key=Platform, Value=${KITCHEN_PLATFORM_NAME}},{Key=ResourceName, Value=${RESOURCE_NAME}}]" \
        --query "VolumeId" --output text)

echo "** EBS volume 1 created: ${KITCHEN_EBS_VOLUME_ID1}"

KITCHEN_EBS_VOLUME_ID2=$(aws ec2 create-volume \
        --region "${KITCHEN_AWS_REGION}" \
        --availability-zone "${KITCHEN_AWS_REGION}${KITCHEN_AVAILABILITY_ZONE}" \
        --size 1 \
        --tag-specifications "ResourceType=volume,Tags=[{Key=Kitchen, Value=true},{Key=Platform, Value=${KITCHEN_PLATFORM_NAME}},{Key=ResourceName, Value=${RESOURCE_NAME}}]" \
        --query "VolumeId" --output text)

echo "** EBS volume 2 created: ${KITCHEN_EBS_VOLUME_ID2}"

sed -i.bak "s#'${RESOURCE_NAME}/${KITCHEN_PLATFORM_NAME}' => .*,#'${RESOURCE_NAME}/${KITCHEN_PLATFORM_NAME}' => %w(${KITCHEN_EBS_VOLUME_ID1} ${KITCHEN_EBS_VOLUME_ID2}),#" "${KITCHEN_ROOT_DIR}/test/environments/kitchen.rb"
