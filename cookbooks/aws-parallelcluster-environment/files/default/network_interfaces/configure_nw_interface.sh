#!/bin/sh
# Configure a specific Network Interface according to the OS
# The configuration involves 3 aspects:
# - Main configuration (IP address, protocol and gateway)
# - A specific routing table, so that all traffic coming to a network interface leaves the instance using the same
#   interface
# - A routing rule to make the OS use the specific routing table for this network interface

set -ex

if
  [ -z "${DEVICE_NUMBER}" ] ||        # index of the device
  [ -z "${NETWORK_CARD_INDEX}" ] ||   # index of the network card
  [ -z "${GW_IP_ADDRESS}" ] ||        # gateway ip address
  [ -z "${CIDR_PREFIX_LENGTH}" ] ||   # the prefix length of the device IP cidr block
  [ -z "${NETMASK}" ]                 # netmask to apply to device ip address
then
  echo 'One or more environment variables missing'
  exit 1
fi

# Check if this is an EFA-only interface (no device name or IP)
if [ -z "${DEVICE_NAME}" ] && [ -z "${DEVICE_IP_ADDRESS}" ]; then
  echo "EFA-only interface detected - skipping IP configuration"
  exit 0
fi

# If one of these is missing but not both, it is an invalid configuration
if [ -z "${DEVICE_NAME}" ] || [ -z "${DEVICE_IP_ADDRESS}" ]; then
    echo "Device name or IP address is missing"
    exit 1
fi

SUFFIX=$NETWORK_CARD_INDEX$(printf "%02d" $DEVICE_NUMBER)

ROUTE_TABLE="$(( $SUFFIX + 1000 ))"

echo "Configuring device name: ${DEVICE_NAME} with IP:${DEVICE_IP_ADDRESS} CIDR_PREFIX:${CIDR_PREFIX_LENGTH} NETMASK:${NETMASK} GW:${GW_IP_ADDRESS} ROUTING_TABLE:${ROUTE_TABLE}"

# config file
FILE="/etc/sysconfig/network-scripts/ifcfg-${DEVICE_NAME}"
if [ ! -f "$FILE" ]; then
/bin/cat <<EOF >${FILE}
DEVICE=${DEVICE_NAME}
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=none
IPADDR=${DEVICE_IP_ADDRESS}
PREFIX=${CIDR_PREFIX_LENGTH}
GATEWAY=${GW_IP_ADDRESS}
MTU="9001"
IPV4_FAILURE_FATAL=yes
NAME="System ${DEVICE_NAME}"
EOF
fi

# route file
FILE="/etc/sysconfig/network-scripts/route-${DEVICE_NAME}"
if [ ! -f "$FILE" ]; then
/bin/cat <<EOF >${FILE}
default via ${GW_IP_ADDRESS} dev ${DEVICE_NAME} table ${ROUTE_TABLE}
default via ${GW_IP_ADDRESS} dev ${DEVICE_NAME} metric ${ROUTE_TABLE}
${DEVICE_IP_ADDRESS} dev ${DEVICE_NAME} table ${ROUTE_TABLE}
EOF
fi

# rule file
FILE="/etc/sysconfig/network-scripts/rule-${DEVICE_NAME}"
if [ ! -f "$FILE" ]; then
/bin/cat <<EOF >${FILE}
from ${DEVICE_IP_ADDRESS} lookup ${ROUTE_TABLE}
EOF
fi