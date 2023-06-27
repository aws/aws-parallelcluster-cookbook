#!/bin/bash

echo "**** pre_destroy"

[[ "${KITCHEN_DRIVER}" = "ec2" ]] || return
[ -z "${KITCHEN_EC2_INSTANCE_ID}" ] && echo "EC2 instance not available. Skipping pre_destroy hook." && exit 0

read KITCHEN_ENI_ID KITCHEN_ATTACHMENT_ID <<< "$(aws ec2 describe-instances --instance-ids "${KITCHEN_EC2_INSTANCE_ID}" \
    --query "Reservations[0].Instances[0].NetworkInterfaces[?Attachment.DeviceIndex==\`1\`].[NetworkInterfaceId, Attachment.AttachmentId]" \
    --region "${KITCHEN_AWS_REGION}" --output text)"

if [ -n "${KITCHEN_ATTACHMENT_ID}" ]; then
  echo "** Detaching ENI: ${KITCHEN_ATTACHMENT_ID}"
  aws ec2 detach-network-interface --attachment-id "${KITCHEN_ATTACHMENT_ID}" --region "${KITCHEN_AWS_REGION}"
fi

if [ -n "${KITCHEN_ENI_ID}" ]; then
  echo "** Waiting for ENI to be detached: ${KITCHEN_ENI_ID}"
  aws ec2 wait network-interface-available --network-interface-ids "${KITCHEN_ENI_ID}" --region "${KITCHEN_AWS_REGION}"

  echo "** Deleting ENI: ${KITCHEN_ENI_ID}"
  aws ec2 delete-network-interface --network-interface-id "${KITCHEN_ENI_ID}" --region "${KITCHEN_AWS_REGION}"
fi
