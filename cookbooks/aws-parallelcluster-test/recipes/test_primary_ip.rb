# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-test
# Recipe:: test_primary_ip
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

bash "check primary ip" do
  cwd Chef::Config[:file_cache_path]
  code <<-TEST
  TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
  macs=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs`
  for mac in $macs
  do
    device_number=`curl -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac}/device-number"`
    network_card=`curl -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac}/network-card"`
    if [[ $device_number == '0' && $network_card == '0' ]]
    then
      IP_HOSTS="$(grep "$HOSTNAME" /etc/hosts | awk '{print $1}')"
      mac_ip=`curl -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac}/local-ipv4s"`
      for word in $IP_HOSTS
      do
        if [[ ${word} == ${mac_ip} ]]
        then
          exit 0
        fi
      done
    fi
  done
  echo Error: Route53 IP does not match host IP
  exit 1
  TEST
end
