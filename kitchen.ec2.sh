#!/bin/bash

# Variables you can set in your local .kitchen.env.sh (not to be pushed)
#
# KITCHEN_AWS_REGION:         AWS region;
#                             falls back to AWS_DEFAULT_REGION, then to eu-west-1
#
# KITCHEN_ARCHITECTURE:       [x86_64|arm64];
#                             default x86_64
#
# KITCHEN_KEY_NAME:           KeyPair to use with EC2 instances
#                             default kitchen
#
# KITCHEN_SUBNET_ID:          subnet-0c8a5dd6c753bec3f
#                             if not set will use Subnet tagged with Kitchen=true
#
# KITCHEN_SECURITY_GROUP_ID:  sg-0ceecc41dfe5499a8
#                             if not set will use SG tagged with Kitchen=true
#
# KITCHEN_SSH_KEY_PATH:       path to private key
#                             default ~/.ssh/${key-name}-${region}.pem
#
# KITCHEN_PCLUSTER_VERSION:   ParallelCluster version to use
#                             defaults to the latest one
#
# KITCHEN_ALINUX2_AMI:        specific AMI to use for alinux2
#                             if not specified, will look for the latest suitable ParallelCluster AMI
#
# KITCHEN_REDHAT8_AMI:        specific AMI to use for redhat8
#                             if not specified, will look for the latest suitable ParallelCluster AMI
#
# KITCHEN_CENTOS7_AMI:        specific AMI to use for centos7
#                             if not specified, will look for the latest suitable ParallelCluster AMI
#
# KITCHEN_UBUNTU18_AMI:       specific AMI to use for ubuntu18.04
#                             if not specified, will look for the latest suitable ParallelCluster AMI
#
# KITCHEN_UBUNTU20_AMI:       specific AMI to use for ubuntu20.04
#                             if not specified, will look for the latest suitable ParallelCluster AMI
#

# Run tests as follows:
# ./kitchen.ec2.sh <context> <kitchen options>
# where <context> is either recipes, resources or validate.
#
# For instance:
# ./kitchen.ec2.sh recipes list
# ./kitchen.ec2.sh recipes test ephemeral-drives-setup --parallel --concurrency 5 -l debug

export KITCHEN_LOCAL_YAML="kitchen.$1.yml"; shift;
export KITCHEN_YAML=kitchen.ec2.yml
export KITCHEN_GLOBAL_YAML=kitchen.global.yml
export KITCHEN_DRIVER=ec2

THIS_DIR=$(dirname "$0")
if [ -e "${THIS_DIR}/.kitchen.env.sh" ]
then
  echo "*** Apply local environment"
  source "${THIS_DIR}/.kitchen.env.sh"
fi

: "${KITCHEN_AWS_REGION:=${AWS_DEFAULT_REGION:-eu-west-1}}"
: "${KITCHEN_KEY_NAME:=kitchen}"
: "${KITCHEN_SSH_KEY_PATH:="~/.ssh/${KITCHEN_KEY_NAME}-${KITCHEN_AWS_REGION}.pem"}"
: "${KITCHEN_AVAILABILITY_ZONE:=a}"

# Subnet
if [ -z "${KITCHEN_SUBNET_ID}" ]; then
  echo "** KITCHEN_SUBNET_ID not explicitly set: looking for subnet tagged Kitchen=true"

  KITCHEN_SUBNET_ID=$(aws ec2 describe-subnets --region "${KITCHEN_AWS_REGION}" \
      --filters "Name=tag:Kitchen,Values=true" \
                "Name=availability-zone,Values=${KITCHEN_AWS_REGION}${KITCHEN_AVAILABILITY_ZONE}" \
      --query 'Subnets[0].SubnetId' --output text)

  echo "** KITCHEN_SUBNET_ID: ${KITCHEN_SUBNET_ID}"

  if [ "${KITCHEN_SUBNET_ID}" = "None" ]; then
    echo "Subnet tagged Kitchen=true not found in AZ ${KITCHEN_AWS_REGION}${KITCHEN_AVAILABILITY_ZONE}"
    exit 1
  fi
fi

# VPC
KITCHEN_VPC_ID=$(aws ec2 describe-subnets --region "${KITCHEN_AWS_REGION}" \
    --subnet-ids "${KITCHEN_SUBNET_ID}" \
    --query 'Subnets[0].VpcId' --output text)

echo "** KITCHEN_VPC_ID: ${KITCHEN_VPC_ID}"

# Security Group
if [ -z "${KITCHEN_SECURITY_GROUP_ID}" ]; then
  echo "** KITCHEN_SECURITY_GROUP_ID not explicitly set"

  if [ -z "${KITCHEN_SECURITY_GROUP_NAME}" ]; then
    echo "** KITCHEN_SECURITY_GROUP_NAME not explicitly set, looking for tag Kitchen=true"

    KITCHEN_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --region "${KITCHEN_AWS_REGION}" \
                --filters "Name=tag:Kitchen,Values=true" "Name=vpc-id,Values=${KITCHEN_VPC_ID}" \
                --query 'SecurityGroups[0].GroupId' --output text)
  else
    echo "** Looking for SG named ${KITCHEN_SECURITY_GROUP_NAME}"

    KITCHEN_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --region "${KITCHEN_AWS_REGION}" \
                --filters "Name=vpc-id,Values=${KITCHEN_VPC_ID}" "Name=group-name,Values=${KITCHEN_SECURITY_GROUP_NAME}" \
                --query 'SecurityGroups[0].GroupId' --output text)
  fi

  echo "** KITCHEN_SECURITY_GROUP_ID: ${KITCHEN_SECURITY_GROUP_ID}"

fi

export KITCHEN_AWS_REGION
export KITCHEN_KEY_NAME
export KITCHEN_SSH_KEY_PATH
export KITCHEN_SUBNET_ID
export KITCHEN_VPC_ID
export KITCHEN_SECURITY_GROUP_ID

kitchen "$@"
