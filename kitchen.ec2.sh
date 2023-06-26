#!/bin/bash

# Variables you can set in your local .kitchen.env.sh (not to be pushed)
#
# KITCHEN_AWS_REGION:         AWS region;
#                             falls back to AWS_DEFAULT_REGION, then to eu-west-1
#
# KITCHEN_ARCHITECTURE:       [x86_64|arm64];
#                             default x86_64
#
# KITCHEN_INSTANCE_TYPE:      instance type to use
#                             default t2.micro
#
# KITCHEN_KEY_NAME:           KeyPair to use with EC2 instances
#                             default kitchen
#
# KITCHEN_SUBNET_ID:          subnet to put EC2 instance into
#                             if not set will use Subnet tagged with Kitchen=true
#
# KITCHEN_SECURITY_GROUP_ID:  security group to associate to the instance
#                             if not set will use SG tagged with Kitchen=true
#
# KITCHEN_IAM_PROFILE:        IAM instance profile name
#                             if not set no profile will be attached
#
# KITCHEN_USER_DATA_SCRIPT:   user-data script to launch on the instance
#                             if not set no user-data script will be launched
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
# KITCHEN_RHEL8_AMI:        specific AMI to use for redhat8
#                             if not specified, will look for the latest suitable ParallelCluster AMI
#
# KITCHEN_CENTOS7_AMI:        specific AMI to use for centos7
#                             if not specified, will look for the latest suitable ParallelCluster AMI
#
# KITCHEN_UBUNTU2004_AMI:       specific AMI to use for ubuntu20.04
#                             if not specified, will look for the latest suitable ParallelCluster AMI
#
# KITCHEN_UBUNTU2204_AMI:       specific AMI to use for ubuntu22.04
#                             if not specified, will look for the latest suitable ParallelCluster AMI
#

source kitchen/kitchen.local-yml.sh

THIS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export KITCHEN_YAML="${THIS_DIR}/kitchen.ec2.yml"
export KITCHEN_GLOBAL_YAML="${THIS_DIR}/kitchen.global.yml"
export KITCHEN_DRIVER=ec2

if [ -e "${THIS_DIR}/.kitchen.env.sh" ]
then
  echo "*** Apply local environment"
  source "${THIS_DIR}/.kitchen.env.sh"
fi

: "${KITCHEN_AWS_REGION:=${AWS_DEFAULT_REGION:-eu-west-1}}"
: "${KITCHEN_KEY_NAME:=kitchen}"
: "${KITCHEN_SSH_KEY_PATH:="~/.ssh/${KITCHEN_KEY_NAME}-${KITCHEN_AWS_REGION}.pem"}"
: "${KITCHEN_AVAILABILITY_ZONE:=a}"
: "${KITCHEN_ARCHITECTURE:=x86_64}"

if [ "$1" == "create" ] || [ "$1" == "converge" ] || [ "$1" == "verify" ] || [ "$1" == "destroy" ] || [ "$1" == "test" ]; then
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
  if [ -z "${KITCHEN_VPC_ID}" ]; then
    echo "** KITCHEN_VPC_ID not explicitly set: deriving from subnet"

    KITCHEN_VPC_ID=$(aws ec2 describe-subnets --region "${KITCHEN_AWS_REGION}" \
        --subnet-ids "${KITCHEN_SUBNET_ID}" \
        --query 'Subnets[0].VpcId' --output text)

    echo "** KITCHEN_VPC_ID: ${KITCHEN_VPC_ID}"
  fi

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
fi

export KITCHEN_AWS_REGION
export KITCHEN_KEY_NAME
export KITCHEN_SSH_KEY_PATH
export KITCHEN_AVAILABILITY_ZONE
export KITCHEN_ARCHITECTURE
export KITCHEN_INSTANCE_TYPE
export KITCHEN_SUBNET_ID
export KITCHEN_VPC_ID
export KITCHEN_SECURITY_GROUP_ID

echo "** KITCHEN_AWS_REGION: ${KITCHEN_AWS_REGION}"
echo "** KITCHEN_KEY_NAME: ${KITCHEN_KEY_NAME}"
echo "** KITCHEN_SSH_KEY_PATH: ${KITCHEN_SSH_KEY_PATH}"
echo "** KITCHEN_AVAILABILITY_ZONE: ${KITCHEN_AVAILABILITY_ZONE}"
echo "** KITCHEN_ARCHITECTURE: ${KITCHEN_ARCHITECTURE}"
echo "** KITCHEN_INSTANCE_TYPE: ${KITCHEN_INSTANCE_TYPE}"
echo "** KITCHEN_SUBNET_ID: ${KITCHEN_SUBNET_ID}"
echo "** KITCHEN_VPC_ID: ${KITCHEN_VPC_ID}"
echo "** KITCHEN_SECURITY_GROUP_ID: ${KITCHEN_SECURITY_GROUP_ID}"
echo "** KITCHEN_IAM_PROFILE: ${KITCHEN_IAM_PROFILE}"
echo "** KITCHEN_LOCAL_YAML: ${KITCHEN_LOCAL_YAML}"
echo "** KITCHEN_YAML: $KITCHEN_YAML"
echo "** KITCHEN_GLOBAL_YAML: $KITCHEN_GLOBAL_YAML"
echo "kitchen $*"

kitchen "$@"
