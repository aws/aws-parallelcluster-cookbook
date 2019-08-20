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


# Generate a 5 year certificate that will be written in the given path . You must be root to perform
# this command

# Usage:  ./generate_certificate.sh "/etc/parallelcluster/cert.pem" dcvextauth dcv

_check_set() {
  file="$1"
  message="$2"
  if [[ -z "${file}" ]]; then
      >&2 echo "${message}"
      exit 1
  fi
}

main() {
  path="$1"
  user="$2"
  group="$3"
  _check_set "${path}" "Path required"
  _check_set "${user}" "User required"
  _check_set "${group}" "Group required"

  openssl req -new -x509 -days 1825 -subj "/CN=localhost" -nodes -out "${path}" -keyout "${path}"
  chmod 440 "${path}"
  chown "${user}":"${group}" "${path}"
}

main "$@"
