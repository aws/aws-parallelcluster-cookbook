#!/bin/bash -x

# This script creates a set of AWS ParallelCluster AMIs.
#
# The following variables must be exported in the environment:
# AWS_FLAVOR_ID=<instance-type>
# AWS_VPC_ID=<us-east-1-vpc-id>
# AWS_SUBNET_ID=<us-east-1-subnet-id>
# NVIDIA_ENABLED=<no|yes>
#
# NOTE: The VPC and the Subnet must be in the us-east-1 region, because the packer templates refer to
# AMI IDs from this region. Moreover, the CentOs AMIs are private to the AWS ParallelCluster account.
#
# Usage: build_ami.sh --os <os> --region <region> --partition <partition> [--public] [--custom] [--build-date <build-date>]
#   os: the os to build (supported values: all|centos6|centos7|alinux|ubuntu1404|ubuntu1604)
#   partition: partition to build in (supported values: commercial|govcloud|china)
#   region: region to copy ami too (supported values: all|us-east-1|us-gov-west-1|...)
#   custom: specifies to create the AMI from a custom AMI-id, which must be specified by variable CUSTOM_AMI_ID in the environment (optional)
#   public: specifies AMIs visibility (optional, default is private)
#   build-date: timestamp to append to the AMIs names (optional)

requirements_check() {
    packer build --help >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
      echo "packer command not found. Is Packer installed?"
      echo "Please visit https://www.packer.io/downloads.html for instruction on how to download and install"
      exit 1
    fi

    berks vendor --help >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
      echo "berks command not found. Is ChefDK installed?"
      echo "Please visit https://downloads.chef.io/chefdk/ for instruction on how to download and install"
      exit 1
    fi
}


parse_options() {
    _os=''
    _partition=''
    _region=''
    _custom=false
    _public=false
    _build_date=''

    if [ $# -eq 0 ]; then
        syntax
        exit 0
    fi

    while [ $# -gt 0 ] ; do
        case "$1" in
            --os)
                _os="$2"
                shift
            ;;
            --os=*)
                _os="${1#*=}"
            ;;
            --partition)
                _partition="$2"
                shift
            ;;
            --partition=*)
                _partition="${1#*=}"
            ;;
            --region)
                _region="$2"
                shift
            ;;
            --region=*)
                _region="${1#*=}"
            ;;
            --custom)
                _custom=true
            ;;
            --public)
                _public=true
            ;;
            --build-date)
                _build_date="$2"
                shift
            ;;
            --build-date=*)
                _build_date="${1#*=}"
            ;;
            -h|--help|help)
                syntax
                exit 0
            ;;
            *)
                syntax
                fail "Unrecognized option '$1'"
            ;;
        esac
        shift
    done
}

check_options() {
    set -e

    available_os="centos6 centos7 alinux ubuntu1404 ubuntu1604 ubuntu1804"
    cwd="$(dirname $0)"
    tmp_dir=$(mktemp -d)
    export VENDOR_PATH="${tmp_dir}/vendor/cookbooks"

    if [ "${_custom}" == "true" ]; then
        only=custom-${_os}
    else
        only=${_os}
    fi

    if [ "x${_os}" == "x" ]; then
      echo "Must provide OS to build. Valid values: ${available_os}"
      exit 1
    fi

    if [ "x${_region}" == "x" ]; then
      echo "Must provide AWS region to copy ami into"
      echo "Options: all us-east-1 us-gov-west-1 ..."
      exit 1
    fi

    if [ "${_public}" == "true" ]; then
      export AMI_PERMS="all"
    fi

    if [ "${_partition}" == "commercial" ]; then
      export AWS_REGION="us-east-1"
    elif [ "${_partition}" == "govcloud" ]; then
      export AWS_REGION="us-gov-west-1"
    elif [ "${_partition}" == "china" ]; then
      export AWS_REGION="cn-north-1"
    elif [ "${_partition}" == "region" ]; then
      export AWS_REGION="${_region}"
    else
      echo "Must provide AWS partition to build for."
      echo "Options: commercial govcloud china region"
      exit 1
    fi

    if [ "${_region}" == "all" ]; then
      available_regions="$(aws ec2 --region ${AWS_REGION} describe-regions --query Regions[].RegionName --output text | tr '\t' ',')"
      export BUILD_FOR=${available_regions}
    else
      export BUILD_FOR=${_region}
    fi
}

do_command() {
    RC=0

    rm -rf "${VENDOR_PATH}" || RC=1
    berks vendor "${VENDOR_PATH}" --berksfile "${cwd}/../Berksfile" || RC=1
    if [ "x${_build_date}" == "x" ]; then
      export BUILD_DATE=$(date +%Y%m%d%H%M)
    else
      export BUILD_DATE=${_build_date}
    fi

    # set it to try for 1 hour, this is to resolve ami copy timeout issue
    # https://github.com/hashicorp/packer/issues/6536
    export AWS_TIMEOUT_SECONDS=3600

    case ${_os} in
      all)
        for x in ${available_os}; do
          packer build -color=false -var-file="${cwd}/packer_variables.json" "${cwd}/packer_${x}.json"
          RC=$?
        done
        ;;
      centos6|centos7|alinux|ubuntu1404|ubuntu1604|ubuntu1804)
        packer build -color=false -var-file="${cwd}/packer_variables.json" -only=${only} "${cwd}/packer_${_os}.json"
        RC=$?
        ;;
      *)
        echo "Unknown OS: ${_os}. Valid values: ${available_os}"
        RC=1
        ;;
    esac

    echo "RC: ${RC}"
    exit ${RC}
}


main() {
    requirements_check
    parse_options "$@"
    check_options
    do_command
}

main "$@"
