#!/bin/bash -x

# This script creates a set of AWS ParallelCluster AMIs.
#
# The following variables must be exported in the environment:
# AWS_FLAVOR_ID=<instance-type>
# AWS_VPC_ID=<us-east-1-vpc-id>
# AWS_SUBNET_ID=<us-east-1-subnet-id>
# NVIDIA_ENABLED=<no|yes>
#
# The following variables can be exported in order to configure packer variables, but the CLI args takes precedent:
# AMI_ARCH=<arch>
#
# NOTE: The VPC and the Subnet must be in the us-east-1 region, because the packer templates refer to
# AMI IDs from this region. Moreover, the CentOs AMIs are private to the AWS ParallelCluster account.
#
# Usage: build_ami.sh --os <os> --region <region> --partition <partition> [--public] [--custom]
#                     [--build-date <build-date>] [--arch <arch>]
#   os: the os to build (supported values: all|centos7|centos8|alinux2|ubuntu1804|ubuntu2004)
#   partition: partition to build in (supported values: commercial|govcloud|china|region)
#   region: region to copy ami too (supported values: all|us-east-1|us-gov-west-1|...)
#   custom: specifies to create the AMI from a custom AMI-id, which must be specified by variable CUSTOM_AMI_ID in the environment (optional)
#   public: specifies AMIs visibility (optional, default is private)
#   build-date: timestamp to append to the AMIs names (optional)
#   arch: Architecture to filter for when selecting AMI to build on, corresponds to AMI_ARCH environment variable
#         (supported values: x86_64|arm64)

requirements_check() {
    currentver="$(packer --version)"
    requiredver="1.4.0"
    packer build --help >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
      echo "packer command not found. Is Packer installed?"
      echo "Please visit https://www.packer.io/downloads.html for instruction on how to download and install"
      exit 1
    elif ! [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
      echo "Packer version == $currentver but must be >= 1.4.0. Is the latest Packer installed?"
      echo "Please visit https://www.packer.io/downloads.html for instruction on how to download and install"
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
    _arch=''

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
            --arch)
                _arch="${2}"
                shift
            ;;
            --arch=*)
                _arch="${1#*=}"
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

    available_arm_os="ubuntu1804 ubuntu2004 alinux2 centos8"  # subset of supported OSes for which ARM AMIs are available
    available_os="centos7 ${available_arm_os}"
    cwd="$(dirname $0)"
    export COOKBOOK_PATH="$(cd ${cwd}/..; pwd)"
    export SCRIPT_PATH="${cwd}/../../script"

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
      export AWS_REGION="${AWS_REGION-us-east-1}"
    elif [ "${_partition}" == "govcloud" ]; then
      export AWS_REGION="${AWS_REGION-us-gov-west-1}"
    elif [ "${_partition}" == "china" ]; then
      export AWS_REGION="${AWS_REGION-cn-north-1}"
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

    # Ensure architecture to build for is known
    if [ -z "${_arch}" ] && [ -z "${AMI_ARCH}" ]; then
      echo "Must specify the architecture to build an AMI for via either --arch or by setting AMI_ARCH"
      exit 1
    elif [ -z "${_arch}" ]; then
      _arch="${AMI_ARCH}"
    fi

    # Ensure architecture is valid
    available_archs="x86_64 arm64"
    case ${_arch} in
      x86_64|arm64)
        export AMI_ARCH="${_arch}"
        ;;
      *)
        echo "Invalid architecture: ${_arch}"
        echo "Must be one of the following: ${available_archs}"
        exit 1
        ;;
    esac

    # Ensure the specified architecture-OS combination is valid
    if [ "${_arch}" == "arm64" ] && [[ "${_os}" == "centos7" ]]; then
      echo "Currently there are no arm64 AMIs available for ${_os}."
      exit 1
    elif [ "${_arch}" == "arm64" ] && [ "${_os}" == "all" ]; then
      echo "Building ARM AMIs for the following OSes: ${available_arm_os}. There are no arm64 AMIs for the other."
      available_os="${available_arm_os}"
    fi
}

do_command() {
    RC=0

    mkdir -p "${SCRIPT_PATH}"

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
      centos7|centos8|ubuntu1804|ubuntu2004|alinux2)
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
