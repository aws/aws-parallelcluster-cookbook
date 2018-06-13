#!/bin/bash -x

# This script creates a set of CfnCluster AMIs.
#
# The following variables must be exported in the environment:
# AWS_FLAVOR_ID=<instance-type>
# AWS_VPC_ID=<us-east-1-vpc-id>
# AWS_SUBNET_ID=<us-east-1-subnet-id>
# NVIDIA_ENABLED=<no|yes>
#
# NOTE: The VPC and the Subnet must be in the us-east-1 region, because the packer templates refer to
# AMI IDs from this region. Moreover, the CentOs AMIs are private to the CfnCluster AWS account.
#
# Usage: build_ami.sh <os> <region> [private|public] [<build-date>]
#   os: the os to build (supported values: all|centos6|centos7|alinux|ubuntu1404|ubuntu1604)
#   region: region to build (supported values: all|us-east-1|...)
#   private|public: specifies AMIs visibility (optional, default is private)
#   build-date: timestamp to append to the AMIs names (optional)

set -e

os=$1
region=$2
public=$3
build_date=$4

available_os="centos6 centos7 alinux ubuntu1404 ubuntu1604"
available_regions="eu-west-1,eu-west-2,eu-west-3,ap-southeast-1,ap-southeast-2,eu-central-1,ap-northeast-1,ap-northeast-2,ap-northeast-3,us-west-2,sa-east-1,us-west-1,us-east-2,ap-south-1,ca-central-1"
cwd="$(dirname $0)"
export VENDOR_PATH="${cwd}/../../vendor/cookbooks"

if [ "x${os}" == "x" ]; then
  echo "Must provide OS to build."
  echo "Options: all ${available_os}"
  exit 1
fi

if [ "x${region}" == "x" ]; then
  echo "Must provide AWS region to build for."
  echo "Options: us-east-1 all"
  exit 1
fi

if [ "${public}" == "public" ]; then
  export AMI_PERMS="all"
fi

if [ "${region}" == "all" ]; then
  export BUILD_FOR=${available_regions}
fi

RC=0

rm -rf "${VENDOR_PATH}" || RC=1
berks vendor "${VENDOR_PATH}" --berksfile "${cwd}/../Berksfile" || RC=1
if [ "x${build_date}" == "x" ]; then
  export BUILD_DATE=$(date +%Y%m%d%H%M)
else
  export BUILD_DATE=${build_date}
fi


case ${os} in
  all)
    for x in ${available_os}; do
      packer build -machine-readable -var-file="${cwd}/packer_variables.json" "${cwd}/packer_${x}.json"
      RC=$?
    done
    ;;
  centos6|centos7|alinux|ubuntu1404|ubuntu1604)
    packer build -machine-readable -var-file="${cwd}/packer_variables.json" "${cwd}/packer_${os}.json"
    RC=$?
    ;;
  *)
    echo "Unknown OS: ${os}"
    RC=1
    ;;
esac

echo "RC: ${RC}"
exit ${RC}
