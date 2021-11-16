#!/bin/bash

# Copyright 2013-2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

set -x
echo "Determining the MAC address"
TOKEN=$(curl --retry 20 --retry-delay 1 --fail -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
MAC=$(curl --retry 20 --retry-delay 1 --silent --fail -H "X-aws-ec2-metadata-token: ${TOKEN}" http://169.254.169.254/latest/meta-data/mac)
if [ $? -ne 0 ] ; then
   echo "Unable to determine MAC address" | logger -t "ec2"
   exit 1
fi
echo "Found MAC: ${MAC} on the first network device" | logger -t "ec2"


VPC_CIDR_URI="http://169.254.169.254/latest/meta-data/network/interfaces/macs/${MAC}/vpc-ipv4-cidr-block"
echo "Metadata location for vpc ipv4 range: ${VPC_CIDR_URI}" | logger -t "ec2"

VPC_CIDR_RANGE=$(curl --retry 20 --retry-delay 1 --silent --fail -H "X-aws-ec2-metadata-token: ${TOKEN}" ${VPC_CIDR_URI})
if [ $? -ne 0 ] ; then
   echo "Unable to retrive VPC CIDR range from meta-data. Using 0.0.0.0/0 instead. PAT may not function correctly" | logger -t "ec2"
   VPC_CIDR_RANGE="0.0.0.0/0"
else
   echo "Retrived the VPC CIDR range: ${VPC_CIDR_RANGE} from meta-data" |logger -t "ec2"
fi


echo "Determining Network Interface name"
INTERFACE_NAME=$(ip -o link | grep -i ${MAC} | cut -d' ' -f2 | sed 's/://')
if [ $? -ne 0 ] ; then
   echo "Unable to determine Network Interface name" | logger -t "ec2"
   exit 1
fi
echo "Found Interface name: ${INTERFACE_NAME} associated to MAC ${MAC}" | logger -t "ec2"


echo 1 >  /proc/sys/net/ipv4/ip_forward && \
   echo 0 >  /proc/sys/net/ipv4/conf/${INTERFACE_NAME}/send_redirects && \
   /sbin/iptables -t nat -A POSTROUTING -o ${INTERFACE_NAME} -s ${VPC_CIDR_RANGE} -j MASQUERADE

if [ $? -ne 0 ] ; then
   echo "Configuration of PAT failed" | logger -t "ec2"
   exit 0
fi

echo "Configuration of PAT complete" |logger -t "ec2"
exit 0
