#!/usr/bin/env bash
#
# Cookbook Name:: aws-parallelcluster
#
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# This script must be executed by the user who want to connect to DCV to obtain a Session Token.
#
# It performs the following steps:
# 1. Asks the ParallelCluster DCV External Authenticator for a Request Token and the Access File name
# 2. Creates the "access file" in the AUTHORIZATION_FILE_DIR folder (to confirm user identity)
# 3. Asks the ParallelCluster DCV External Authenticator for a SessionToken (the real token to access to the DCV session)
# 4. Returns DCV Session Id, DCV Server Port and the Session Token

# Requirements:
# jq, curl, awk, xargs, shuf, cat, grep, systemctl

# Usage:
# The script requires the ParallelCluster shared folder as input parameter
# The ParallelCluster shared folder will be used as session storage folder for DCV.
# It enables the clients to share files while connected to the session.
# ./pcluster_dcv_connect.sh "/shared"


# Returns the sessionid, the port and the tokenid (256 character long).
# Example: mysession 8443 adfsaklcxzvsadkhfgsdkhjfag-__bafbdajshsdjfh

AUTHORIZATION_FILE_DIR="/var/spool/parallelcluster/pcluster_dcv_authenticator"
DCV_SESSION_FOLDER="${HOME}/.parallelcluster/dcv"
LOG_FILE_PATH="/var/log/parallelcluster/pcluster_dcv_connect.log"
LOG_FILE_MAX_SIZE=5242880 # 5MB


_fail() {
  message=$1
  >&2 echo "ERROR: ${message}"
  exit 1
}

_validate_json() {
  json_param=$1
  message=$2

  if [[ -z "${json_param}" ]]; then
      _fail "${message}. Empty JSON."
  fi
  if ! $(jq -e . >/dev/null 2>&1 <<<"${json_param}"); then
      _fail "${message}. Wrong JSON."
  fi
}

_atomic_touch() {
    file_path="$1"

    _umask=$(umask)
    umask 0022 && touch "${file_path}"
    umask ${_umask}

    if [[ ! -f "${file_path}" ]]; then
        _fail "Unable to create the file in the $(dirname "${file_path}") folder. Exiting.."
    fi
}

_log() {
    text=$1

    [[ -f "${LOG_FILE_PATH}" ]] || _atomic_touch "${LOG_FILE_PATH}"

    # create a backup of the file if the size exceeds the LOG_FILE_MAX_SIZE
    file_size=$(du -b ${LOG_FILE_PATH} | awk '{print $1}')
    if [[ ${file_size} -gt ${LOG_FILE_MAX_SIZE} ]]; then
        mv "${LOG_FILE_PATH}" "${LOG_FILE_PATH}.1"
    fi

    # append log
    log_time=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[${log_time}]: ${text}" >> "${LOG_FILE_PATH}"
}

_create_dcv_session() {
    dcv_session_file="$1"
    shared_folder_path="$2"

    _log "Creating a new NICE DCV session..."
    # Generate a random session id
    sessionid=$(shuf -zer -n20  {A..Z} {a..z} {0..9})
    echo "${sessionid}" > "${dcv_session_file}"
    dcv create-session --type virtual --storage-root "${shared_folder_path}" "${sessionid}"
    _log "NICE DCV session created successfully."

    echo "${sessionid}"
}

main() {
    _log "--- Initializing NICE DCV authentication... ---"

    if [[ -z "$1" ]]; then
        _fail "The script requires the shared folder as input parameter."
    fi

    shared_folder_path="$1"
    user=$(whoami)
    os=$(< /etc/chef/dna.json jq -r .cfncluster.cfn_base_os)
    _log "Input parameters: user: ${user}, OS: ${os}, shared_folder_path: ${shared_folder_path}."

    if ! [[ "${os}" =~ ^(alinux2|ubuntu1804|ubuntu2004|centos[7-8])$ ]]; then
        _fail "OS not supported."
    fi

    if ! systemctl is-active --quiet dcvserver; then
        _fail "NICE DCV service is not active on the given instance."
    fi

    # Create a session with session storage enabled.
    mkdir -p "${DCV_SESSION_FOLDER}"
    dcv_session_file="${DCV_SESSION_FOLDER}/dcv_session"
    if [[ ! -e ${dcv_session_file} ]]; then
        sessionid=$(_create_dcv_session "${dcv_session_file}" "${shared_folder_path}")
    else
        sessionid=$(cat "${dcv_session_file}")
        _log "Reusing existing NICE DCV session for the current user."

        # number of session can either be 0 or 1
        number_of_sessions=$(dcv list-sessions |& grep "${user}" | grep -c "${sessionid}")
        if (( number_of_sessions == 0 )); then
            # There is no running session (e.g. the system has been rebooted)
            _log "There are no running sessions for the current user, creating a new one.."
            sessionid=$(_create_dcv_session "${dcv_session_file}" "${shared_folder_path}")
        fi
    fi

    # xargs to remove eventual whitespaces
    dcv_server_port=$(grep web-port= /etc/dcv/dcv.conf| awk -F'=' '{ print $2 }' | xargs)
    ext_auth_port=$((dcv_server_port + 1))

    # Retrieve Request Token and Access File name
    _log "Retrieving Request Token and Access File name.."
    user_token_request=$(curl --retry 3 --max-time 5 -s -k -X GET -G "https://localhost:${ext_auth_port}" -d action=requestToken -d authUser="${user}" -d sessionID="${sessionid}")
    _validate_json "${user_token_request}" "Unable to obtain the Request Token from the NICE DCV external authenticator."
    request_token=$(echo "${user_token_request}" | jq -r .requestToken)
    access_file=$(echo "${user_token_request}" | jq -r .accessFile)
    _log "Request Token and Access File name obtained successfully."

    # Create the access file in the AUTHORIZATION_FILE_DIR with 644 permissions
    # This is used by the external authenticator to verify the user declares himself as who he really is
    _log "Creating access file.."
    _atomic_touch "${AUTHORIZATION_FILE_DIR}/${access_file}"
    _log "Access file created successfully."


    # Retrieve Session Token
    _log "Retrieving Session Token.."
    session_token_request=$(curl --retry 3 --max-time 5 -s -k -X GET -G "https://localhost:${ext_auth_port}" -d action=sessionToken -d requestToken="${request_token}")
    _validate_json "${session_token_request}" "Unable to obtain the Session Token from the NICE DCV external authenticator."
    session_token=$(echo "${session_token_request}" | jq -r .sessionToken)
    _log "Session Token obtained successfully."

    if [[ -z "${dcv_server_port}" ]]; then
      dcv_server_port=8443
    fi

    _log "--- NICE DCV authentication performed successfully. ---"
    echo "PclusterDcvServerPort=${dcv_server_port} PclusterDcvSessionId=${sessionid} PclusterDcvSessionToken=${session_token}"
}

main "$@"
