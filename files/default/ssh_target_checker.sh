#!/bin/bash

# Copyright 2013-2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

set -o pipefail

log() {
    echo "$@" | logger -t "pcluster_ssh_target_checker"
}

retrieve_vpc_cidr_list() {
    if ! mac=$(curl --retry 3 --retry-delay 0 --silent --fail http://169.254.169.254/latest/meta-data/mac); then
       log  "Unable to determine MAC address for network interface"
       exit 1
    fi

    vpc_cidr_uri="http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac}/vpc-ipv4-cidr-blocks"
    if ! mapfile -t vpc_cidr_list < <(curl --retry 3 --retry-delay 0 --silent --fail "${vpc_cidr_uri}"); then
       log "Unable to retrieve VPC CIDR list from EC2 meta-data"
       exit 1
    fi

    echo "${vpc_cidr_list[@]}"
}

convert_ip_to_decimal() {
    IFS=./ read -r x y z t mask <<< "${1}"
    echo -n "$((x<<24|y<<16|z<<8|t))"
}

convert_mask_to_decimal() {
    IFS=/ read -r _ mask <<< "${1}"
    echo -n "$((-1<<(32-mask)))"
}

check_ip_in_cidr() {
        target_address=$(convert_ip_to_decimal "${1}")
        base_address=$(convert_ip_to_decimal "${2}")
        base_mask=$(convert_mask_to_decimal "${2}")

        if (( (target_address&base_mask) == (base_address&base_mask) )); then
            return 0
        fi

        return 1
}

target_host=$1
if [[ -z "${target_host}" ]]; then
   log  "No input target host"
   exit 1
fi

if ! resolved_ip=$(getent ahosts "${target_host}" | grep -v : | head -1 | cut -d' ' -f1); then
   log "Cannot resolve target Host ${target_host}"
   exit 1
fi

if [[ "${resolved_ip}" == "127.0.0.1" ]]; then
   # Special case for localhost
   log "Target Host ${target_host} is in VPC CIDR"
   exit 0
fi

IFS=" " read -r -a vpc_cidr_list <<< "$(retrieve_vpc_cidr_list)"

for vpc_cidr in "${vpc_cidr_list[@]}"
do
  check_ip_in_cidr "${resolved_ip}" "${vpc_cidr}"
  if check_ip_in_cidr "${resolved_ip}" "${vpc_cidr}"; then
    log "Target Host ${target_host} is in VPC CIDR ${vpc_cidr}"
    exit 0
  fi
done

log  "Target Host ${target_host} is not in any VPC CIDR ${vpc_cidr_list[*]}"
exit 1
