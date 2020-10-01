#!/bin/sh
# Configure a specific Network Interface according to the OS
# The configuration involves 3 aspects:
# - Main configuration (IP address, protocol and gateway)
# - A specific routing table, so that all traffic coming to a network interface leaves the instance using the same
#   interface
# - A routing rule to make the OS use the specific routing table for this network interface

set -e

if
  [ -z "${DEVICE_NAME}" ] ||          # name of the device
  [ -z "${DEVICE_NUMBER}" ] ||        # number of the device
  [ -z "${GW_IP_ADDRESS}" ] ||        # gateway ip address
  [ -z "${DEVICE_IP_ADDRESS}" ] ||    # ip address to assign to the interface
  [ -z "${CIDR_PREFIX_LENGTH}" ] ||   # the prefix length of the device IP cidr block
  [ -z "${NETMASK}" ]                 # netmask to apply to device ip address
then
  echo 'One or more environment variables missing'
  exit 1
fi

if [ "${DEVICE_NUMBER}" = "0" ]
  then
    echo "Device 0 is already configured in Ubuntu 16.04"
    exit 0
fi

FILE="/etc/network/interfaces.d/${DEVICE_NAME}.cfg"
ROUTE_TABLE="100${DEVICE_NUMBER}"

/bin/cat <<EOF >${FILE}
auto ${DEVICE_NAME}
iface ${DEVICE_NAME} inet static
address ${DEVICE_IP_ADDRESS}
netmask ${NETMASK}

# Gateway configuration
up ip route add default via ${GW_IP_ADDRESS} dev ${DEVICE_NAME} table ${ROUTE_TABLE}
up ip route add default via ${GW_IP_ADDRESS} dev ${DEVICE_NAME} metric ${ROUTE_TABLE}

# Routes and rules
up ip route add ${DEVICE_IP_ADDRESS} dev ${DEVICE_NAME} table ${ROUTE_TABLE}
up ip rule add from ${DEVICE_IP_ADDRESS} lookup ${ROUTE_TABLE}
EOF