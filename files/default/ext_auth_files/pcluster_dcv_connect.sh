#!/usr/bin/env bash

#
# Cookbook Name:: aws-parallelcluster
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Requirements:
# jq, curl, awk, xargs, shuf, cat, grep, systemctl

# This script takes as input the ParallelCluster shared folder. So for example you should called it like
# ./pcluster_dcv_connect.sh "/shared"

# Return the sessionid, the port and the tokenid (256 character long).
# Example: mysession 8443 adfsaklcxzvsadkhfgsdkhjfag-__bafbdajshsdjfh

_fail() {
  message=$1
  >&2 echo "${message}"
  exit 1
}

_check_if_empty() {
  variable=$1
  message=$2
  if [[ -z "${variable}" ]]; then
    _fail "${message}"
  fi
}

create_dcv_session() {
    dcv_session_file=$1
    shared_folder_path=$2

    sessionid=$(shuf -zer -n20  {A..Z} {a..z} {0..9})
    echo "${sessionid}" > "${dcv_session_file}"
    dcv create-session --type virtual --storage-root "${shared_folder_path}" "${sessionid}"

    echo "${sessionid}"
}

main() {
    if [[ -z "$1" ]]; then
      _fail "Required shared folder"
    fi

    shared_folder_path=$1
    user=$(whoami)
    os=$(< /tmp/dna.json jq -r .cfncluster.cfn_base_os)

    if [[ ${os} != "centos7" ]]; then
      _fail "Non supported OS"
    fi

    if ! systemctl is-active --quiet dcvserver; then
        _fail "NICE DCV is not active on the given instance"
    fi

    dcv_session_folder="${HOME}/.parallelcluster/dcv"
    mkdir -p "${dcv_session_folder}"

    dcv_session_file="${dcv_session_folder}/dcv_session"
    if [[ ! -e ${dcv_session_file} ]]; then
        sessionid=$(create_dcv_session "${dcv_session_file}" "${shared_folder_path}")
    else
        sessionid=$(cat "${dcv_session_file}")

        # number of session can either be 0 or 1
        number_of_sessions=$(dcv list-sessions |& grep "${user}" | grep -c "${sessionid}")
        if (( number_of_sessions == 0 )); then
            # The system has been rebooted
            sessionid=$(create_dcv_session "${dcv_session_file}" "${shared_folder_path}")
        fi
    fi

    # xargs to remove eventual whitespaces
    dcv_server_port=$(grep web-port= /etc/dcv/dcv.conf| awk -F'=' '{ print $2 }' | xargs)
    ext_auth_port=$((dcv_server_port + 1))

    user_token_request=$(curl --retry 3 --max-time 5 -s -k -X GET -G "https://localhost:${ext_auth_port}" -d action=requestToken -d authUser="${user}" -d sessionID="${sessionid}")
    _check_if_empty "${user_token_request}" "Unable to obtain the User Token from the NICE DCV external authenticator"

    filename=$(echo "${user_token_request}" | jq -r .requiredFile)
    request_token=$(echo "${user_token_request}" | jq -r .requestToken)

    # This is for the external authenticator to be sure you declared yourself as who you really are
    touch "/run/parallelcluster/dcv_ext_auth/${filename}"

    session_token_request=$(curl --retry 3 --max-time 5 -s -k -X GET -G "https://localhost:${ext_auth_port}" -d action=sessionToken -d requestToken="${request_token}")
    _check_if_empty "${session_token_request}" "Unable to obtain the Session Token from the NICE DCV external authenticator"

    session_token=$(echo "${session_token_request}" | jq -r .sessionToken)

    if [[ -z "${dcv_server_port}" ]]; then
      dcv_server_port=8443
    fi

    echo "${sessionid} ${dcv_server_port} ${session_token}"
}

main "$@"
