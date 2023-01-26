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

THIS_DIR=$(dirname "$0")
if [ -e "${THIS_DIR}/.kitchen.env.sh" ]
then
  echo "*** Apply local environment"
  source "${THIS_DIR}/.kitchen.env.sh"
fi

kitchen "$@"
