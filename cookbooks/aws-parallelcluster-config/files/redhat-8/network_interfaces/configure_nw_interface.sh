#!/bin/sh
# Configure a specific Network Interface according to the OS
# The configuration involves 3 aspects:
# - Main configuration (IP address, protocol and gateway)
# - A specific routing table, so that all traffic coming to a network interface leaves the instance using the same
#   interface
# - A routing rule to make the OS use the specific routing table for this network interface

# RedHat 8 official documentation:
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/configuring-policy-based-routing-to-define-alternative-routes_configuring-and-managing-networking

set -e

if
  [ -z "${DEVICE_NAME}" ] ||          # name of the device
  [ -z "${DEVICE_NUMBER}" ] ||        # number of the device
  [ -z "${GW_IP_ADDRESS}" ] ||        # gateway ip address
  [ -z "${DEVICE_IP_ADDRESS}" ] ||    # ip address to assign to the interface
  [ -z "${CIDR_PREFIX_LENGTH}" ]      # the prefix length of the device IP cidr block
then
  echo 'One or more environment variables missing'
  exit 1
fi

con_name="System ${DEVICE_NAME}"
route_table="100${DEVICE_NUMBER}"
priority="100${DEVICE_NUMBER}"
metric="100${DEVICE_NUMBER}"

# Rename connection
original_con_name=`nmcli -t -f GENERAL.CONNECTION device show ${DEVICE_NAME} | cut -f2 -d':'`
sudo nmcli connection modify "${original_con_name}" con-name "${con_name}" ifname ${DEVICE_NAME}

configured_ip=`nmcli -t -f IP4.ADDRESS device show ${DEVICE_NAME} | cut -f2 -d':'`
if [ -z "${configured_ip}" ]; then
  # Setup connection method to "manual", configure ip address and gateway, only if not already configured.
  sudo nmcli connection modify "${con_name}" ipv4.method manual ipv4.addresses ${DEVICE_IP_ADDRESS}/${CIDR_PREFIX_LENGTH} ipv4.gateway ${GW_IP_ADDRESS}
fi

# Setup routes
# This command uses the ipv4.routes parameter to add a static route to the routing table with ID ${route_table}.
# This static route for 0.0.0.0/0 uses the IP of the gateway as next hop.
sudo nmcli connection modify "${con_name}" ipv4.routes "0.0.0.0/0 ${GW_IP_ADDRESS} ${metric} table=${route_table}"

# Setup routing rules
# The command uses the ipv4.routing-rules parameter to add a routing rule with priority ${priority} that routes
# traffic from ${DEVICE_IP_ADDRESS} to table ${route_table}. Low values have a high priority.
# The syntax in the ipv4.routing-rules parameter is the same as in an "ip rule add" command,
# except that ipv4.routing-rules always requires specifying a priority.
sudo nmcli connection modify "${con_name}" ipv4.routing-rules "priority ${priority} from ${DEVICE_IP_ADDRESS} table ${route_table}"

# Reapply previous connection modification.
sudo nmcli device reapply ${DEVICE_NAME}
