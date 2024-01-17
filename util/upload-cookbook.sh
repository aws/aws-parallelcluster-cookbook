#!/bin/bash

_error_exit() {
  echo "ERROR: $1"
  exit 1
}

_info() {
  echo "INFO: $1"
}

_help() {
    local -- _cmd
    _cmd=$(basename "$0")

    cat <<EOF

  Usage: ${_cmd} [OPTION]...

  Copy the AWS ParallelCluster Cookbook in an S3 bucket.

  --bucket <bucket>             Bucket where upload the cookbook
  --srcdir <src-dir>            Root folder of the cookbook project
  --profile <aws-profile>       AWS profile name to use for the upload
                                (optional, default is AWS_PROFILE env variable or "default")
  --region <aws-region>         Region to use for AWSCli commands (optional, default is "us-east-1")
  -h, --help                    Print this help message
EOF
}

main() {
    # parse input options
    while [ $# -gt 0 ] ; do
        case "$1" in
            --bucket)           _bucket="$2"; shift;;
            --bucket=*)         _bucket="${1#*=}";;
            --srcdir)           _srcdir="$2"; shift;;
            --srcdir=*)         _srcdir="${1#*=}";;
            --profile)          _profile="$2"; shift;;
            --profile=*)        _profile="${1#*=}";;
            --region)           _region="$2"; shift;;
            --region=*)         _region="${1#*=}";;
            -h|--help|help)     _help; exit 0;;
            *)                  _help; echo "[error] Unrecognized option '$1'"; exit 1;;
        esac
        shift
    done

    # verify required parameters
    if [ -z "${_bucket}" ]; then
        _error_exit "--bucket parameter not specified"
        _help;
    fi
    if [ -z "${_srcdir}" ]; then
        _error_exit "--srcdir parameter not specified"
        _help;
    fi

    # initialize optional parameters
    if [ -z "${AWS_PROFILE}" ] && [ -z "${_profile}" ]; then
        _info "--profile parameter not specified, using 'default'"
    elif [ -n "${_profile}" ]; then
        _profile="--profile ${_profile}"
    fi
    if [ -z "${_region}" ]; then
        _info "--region parameter not specified, using 'us-east-1'"
        _region="us-east-1"
    fi

    # check bucket or create it
    aws ${_profile} s3api head-bucket --bucket "${_bucket}" --region "${_region}"
    if [ $? -ne 0 ]; then
        _info "Bucket ${_bucket} do not exist, trying to create it"
        aws ${_profile} s3api create-bucket --bucket "${_bucket}" --region "${_region}"
        if [ $? -ne 0 ]; then
            _error_exit "Unable to create bucket ${_bucket}"
        fi
    fi

    _version=$(grep "^version" "${_srcdir}/metadata.rb" | awk '{print $2}'| tr -d \')
    if [ -z "${_version}" ]; then
        _error_exit "Unable to detect cookbook version, are you in the right directory?"
    fi
    _info "Detected version ${_version}"

    # Create archive and md5
    _cwd=$(pwd)
    pushd "${_srcdir}" > /dev/null || exit
    _stashName=$(git stash create)
    git archive --format tar --prefix="aws-parallelcluster-cookbook-${_version}/" "${_stashName:-HEAD}" | gzip > "${_cwd}/aws-parallelcluster-cookbook-${_version}.tgz"
    #tar zcvf "${_cwd}/aws-parallelcluster-cookbook-${_version}.tgz" --transform "s,^aws-parallelcluster-cookbook/,aws-parallelcluster-cookbook-${_version}/," ../aws-parallelcluster-cookbook
    popd > /dev/null || exit
    md5sum aws-parallelcluster-cookbook-${_version}.tgz > aws-parallelcluster-cookbook-${_version}.md5

    # upload packages
    _key_path="parallelcluster/${_version}/cookbooks"
    aws ${_profile} --region "${_region}" s3 cp aws-parallelcluster-cookbook-${_version}.tgz s3://${_bucket}/${_key_path}/aws-parallelcluster-cookbook-${_version}.tgz || _error_exit 'Failed to push cookbook to S3'
    aws ${_profile} --region "${_region}" s3 cp aws-parallelcluster-cookbook-${_version}.md5 s3://${_bucket}/${_key_path}/aws-parallelcluster-cookbook-${_version}.md5 || _error_exit 'Failed to push cookbook md5 to S3'
    aws ${_profile} --region "${_region}" s3api head-object --bucket ${_bucket} --key ${_key_path}/aws-parallelcluster-cookbook-${_version}.tgz --output text --query LastModified > aws-parallelcluster-cookbook-${_version}.tgz.date || _error_exit 'Failed to fetch LastModified date'
    aws ${_profile} --region "${_region}" s3 cp aws-parallelcluster-cookbook-${_version}.tgz.date s3://${_bucket}/${_key_path}/aws-parallelcluster-cookbook-${_version}.tgz.date || _error_exit 'Failed to push cookbook date'

    _bucket_region=$(aws ${_profile} s3api get-bucket-location --bucket ${_bucket} --output text)
    if [ ${_bucket_region} = "None" ]; then
        _bucket_region=""
    else
        _bucket_region=".${_bucket_region}"
    fi

    echo ""
    echo "Done. Add the following configuration to the pcluster create config file:"
    echo ""
    echo "DevSettings:"
    echo "  Cookbook:"
    echo "    ChefCookbook: s3://${_bucket}/${_key_path}/aws-parallelcluster-cookbook-${_version}.tgz"
}

main "$@"

# vim:syntax=sh
