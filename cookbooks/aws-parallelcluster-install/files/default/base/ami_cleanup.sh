#!/bin/bash

rm -rf /var/tmp/* /tmp/*
rm -rf /var/lib/cloud/instances/*
rm -f /var/lib/cloud/instance
rm -rf /etc/ssh/ssh_host_*
rm -f /etc/udev/rules.d/70-persistent-net.rules
grep -l "Created by cloud-init on instance boot automatically" /etc/sysconfig/network-scripts/ifcfg-* | xargs rm -f
rm -rf /var/crash/*

# https://bugs.centos.org/view.php?id=13836#c33128
source /etc/os-release
if [ "${ID}${VERSION_ID}" == "centos7" ]; then
    rm -f /etc/sysconfig/network-scripts/ifcfg-eth0
fi

find /var/log -type f -exec /bin/rm -v {} \;
touch /var/log/lastlog
