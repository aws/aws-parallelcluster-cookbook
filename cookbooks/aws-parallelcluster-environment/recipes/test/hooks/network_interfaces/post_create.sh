#!/bin/bash

echo "**** post_create"

[[ "${KITCHEN_DRIVER}" = "ec2" ]] || return

echo "** Creating ENI..."

KITCHEN_ENI_ID=$(aws ec2 create-network-interface --region "${KITCHEN_AWS_REGION}" \
    --description "Kitchen tests ENI for ${KITCHEN_SUITE_NAME} on ${KITCHEN_EC2_INSTANCE_ID}" \
    --subnet-id "${KITCHEN_SUBNET_ID}" \
    --groups "${KITCHEN_SECURITY_GROUP_ID}" \
    --tag-specifications "ResourceType=network-interface,Tags=[{Key=Kitchen, Value=true}]" \
    --query "NetworkInterface.NetworkInterfaceId" --output text)

echo "** ENI created: ${KITCHEN_ENI_ID}"

aws ec2 attach-network-interface --region "${KITCHEN_AWS_REGION}" \
    --device-index 1 --instance-id "${KITCHEN_EC2_INSTANCE_ID}" \
    --network-interface-id "${KITCHEN_ENI_ID}" \
    --network-card-index 1
