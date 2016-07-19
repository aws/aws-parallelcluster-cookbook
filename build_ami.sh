#!/bin/bash -x

set -e

os=$1
region=$2
public=$3
build_date=$4

available_os="centos6 centos7 alinux ubuntu1404 ubuntu1604"
available_regions="eu-west-1,ap-southeast-1,ap-southeast-2,eu-central-1,ap-northeast-1,ap-northeast-2,us-east-1,sa-east-1,us-west-1"

if [ "x$os" == "x" ]; then
  echo "Must provide OS to build."
  echo "Options: all $available_os"
  exit 1
fi

if [ "x$region" == "x" ]; then
  echo "Must provide AWS region to build for."
  echo "Options: us-west-2 all"
  exit 1
fi

if [ "$public" == "public" ]; then
  export AMI_PERMS="all"
fi

if [ "$region" == "all" ]; then
  export BUILD_FOR=$available_regions
fi

RC=0

rm -rf ../vendor/cookbooks || RC=1
berks vendor ../vendor/cookbooks || RC=1
if [ "x$build_date" == "x" ]; then
  export BUILD_DATE=`date +%Y%m%d%H%M`
else
  export BUILD_DATE=$build_date
fi

case $os in
all)
  for x in $available_os; do
    (packer build -machine-readable -var-file=packer_variables.json packer_$x.json; RC=$?) | tee build-$x.log
    RC=$?
  done
  ;;
centos6)
  (packer build -machine-readable -var-file=packer_variables.json packer_$os.json; RC=$?) | tee build-$os.log
  RC=$?
  ;;
centos7)
  (packer build -machine-readable -var-file=packer_variables.json packer_$os.json; RC=$?) | tee build-$os.log
  RC=$?
  ;;
alinux)
  (packer build -machine-readable -var-file=packer_variables.json packer_$os.json; RC=$?) | tee build-$os.log
  RC=$?
  ;;
ubuntu1404)
  (packer build -machine-readable -var-file=packer_variables.json packer_$os.json; RC=$?) | tee build-$os.log
  RC=$?
  ;;
ubuntu1604)
  (packer build -machine-readable -var-file=packer_variables.json packer_$os.json; RC=$?) | tee build-$os.log
  RC=$?
  ;;
*)
  echo "Unknown OS: $os"
  exit 1
  ;;
esac

echo "RC: $RC"
exit $RC
