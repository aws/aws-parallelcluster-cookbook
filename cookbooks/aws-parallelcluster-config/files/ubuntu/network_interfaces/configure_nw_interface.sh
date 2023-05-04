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
  [ -z "${NETMASK}" ] ||              # netmask to apply to device ip address
  [ -z "${CIDR_BLOCK}" ]              # (full) subnet cidr block
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

# NOTE: In Ubuntu 20.04 all network interfaces are already configured in 50-cloud-init.yaml with dhcp4 enabled.
# However, the specific configuration files created below (in the same way of Ubuntu 18) will override these initial
# settings, as can be verified with the command `netplan get`
grep "${DEVICE_NAME}:" /etc/netplan/50-cloud-init.yaml 1>/dev/null && STATIC_IP_CONFIG=""
if [ "${STATIC_IP_CONFIG}" = "" ]
  then
    echo "Device ${DEVICE_NAME} is dhcp managed in current platform"
  else
    echo "Device ${DEVICE_NAME} IP address will be set to ${DEVICE_IP_ADDRESS}"
fi

FILE="/etc/netplan/${DEVICE_NAME}.yaml"
ROUTE_TABLE="100${DEVICE_NUMBER}"

echo "Configuring ${DEVICE_NAME} with IP:${DEVICE_IP_ADDRESS} CIDR_PREFIX:${CIDR_PREFIX_LENGTH} NETMASK:${NETMASK} GW:${GW_IP_ADDRESS} ROUTING_TABLE:${ROUTE_TABLE}"

/bin/cat <<EOF >${FILE}
network:
  version: 2
  renderer: networkd
  ethernets:
    ${DEVICE_NAME}:
$STATIC_IP_CONFIG
      mtu: '9001'
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

# Hook to delete automatic routes to subnet automatically created from kernel.
# This is needed in Ubuntu 18 because they are generated in the reverse order in which the network interfaces are
# attached and this prevents the primary Network Interface from being selected to communicate in the subnet.
# In Ubuntu 20 this hook is needed as well for a slightly different reason. Automatic routes here are
# already present due to cloud-init initialization and we need to remove them to make sure that the primary Network
# Interface is selected when opening connections to the subnet
FILE="/etc/networkd-dispatcher/routable.d/cleanup-routes.sh"

if [ ! -f "$FILE" ]; then
/bin/cat <<EOF >${FILE}
#!/bin/sh

logger -t parallelcluster "Removing Automatic route for Interface: \${IFACE}"
ip route del ${CIDR_BLOCK} dev \${IFACE}
logger -t parallelcluster "Automatic route removed for Interface: \${IFACE}"
EOF

# The hook script file must be executable and owned by root
chmod 755 ${FILE}
fi
