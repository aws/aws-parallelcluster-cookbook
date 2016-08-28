#!/bin/bash

rm -rf /var/tmp/* /tmp/*
rm -rf /var/lib/cloud/instances/*
rm -f /var/lib/cloud/instance
rm -rf /etc/ssh/ssh_host_*
rm -f /etc/udev/rules.d/70-persistent-net.rules
find /var/log -type f -exec /bin/rm -v {} \;
touch /var/log/lastlog