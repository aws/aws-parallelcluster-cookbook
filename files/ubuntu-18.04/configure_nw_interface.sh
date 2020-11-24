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

STATIC_IP_CONFIG=$(cat<<END
      addresses:
       - ${DEVICE_IP_ADDRESS}/${CIDR_PREFIX_LENGTH}
      dhcp4: no
END
)

if [ "${DEVICE_NUMBER}" = "0" ]
  then
    echo "Device 0 is dhcp managed in Ubuntu 18.04"
    STATIC_IP_CONFIG=""
fi

FILE="/etc/netplan/${DEVICE_NAME}.yaml"
ROUTE_TABLE="100${DEVICE_NUMBER}"

/bin/cat <<EOF >${FILE}
network:
  version: 2
  renderer: networkd
  ethernets:
    ${DEVICE_NAME}:
$STATIC_IP_CONFIG
      routes:
       - to: 0.0.0.0/0
         via: ${GW_IP_ADDRESS} # Default gateway
         table: ${ROUTE_TABLE}
       - to: 0.0.0.0/0
         via: ${GW_IP_ADDRESS} # Default gateway
         metric: ${ROUTE_TABLE}
       - to: ${DEVICE_IP_ADDRESS}
         via: 0.0.0.0
         scope: link
         table: ${ROUTE_TABLE}
      routing-policy:
        - from: ${DEVICE_IP_ADDRESS}
          table: ${ROUTE_TABLE}
EOF