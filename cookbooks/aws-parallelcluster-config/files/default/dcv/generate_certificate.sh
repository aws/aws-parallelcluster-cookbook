#!/usr/bin/env bash
#
# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.


# Generate a 5 year self-signed certificate and a new RSA private key and copy in the given path.
# The command must be executed as root.

# Usage:
# ./generate_certificate.sh \
#     "/etc/parallelcluster/ext-auth-certificate.pem" \
#     "/etc/parallelcluster/ext-auth-private-key.pem" \
#     dcv-ext-auth-user \
#     dcv-ext-auth-user-group

_check_param() {
    paramValue="$1"
    errorMessage="$2"
    if [[ -z "${paramValue}" ]]; then
        >&2 echo "${errorMessage}"
        exit 1
    fi
}

main() {
    certificatePath="$1"
    privateKeyPath="$2"
    user="$3"
    group="$4"

    _check_param "${certificatePath}" "Certificate file path required"
    _check_param "${privateKeyPath}" "Private Key file path required"
    _check_param "${user}" "User required"
    _check_param "${group}" "Group required"

    # Generate a new certificate and a new RSA private key
    openssl req -newkey rsa:2048 -sha256 -x509 -days 1825 -subj "/CN=localhost" -out "${certificatePath}" -nodes -keyout "${privateKeyPath}"
    chmod 440 "${certificatePath}" "${privateKeyPath}"
    chown "${user}":"${group}" "${certificatePath}" "${privateKeyPath}"
}

main "$@"
