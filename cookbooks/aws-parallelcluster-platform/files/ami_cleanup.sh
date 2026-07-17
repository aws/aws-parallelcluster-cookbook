#!/bin/bash

IS_OFFICIAL_AMI_BUILD=${1:-"false"}

# clean up cloud init artifacts https://cloudinit.readthedocs.io/en/latest/topics/cli.html#clean
cloud-init clean -s

rm -rf /var/tmp/* /tmp/*
rm -rf /opt/parallelcluster/tmp/*
rm -rf /etc/ssh/ssh_host_*
rm -f /etc/udev/rules.d/70-persistent-net.rules
grep -l "Created by cloud-init on instance boot automatically" /etc/sysconfig/network-scripts/ifcfg-* | xargs rm -f
rm -rf /var/crash/*

if [ -f /opt/parallelcluster/pin_releasesever ]; then
  rm -f /opt/parallelcluster/pin_releasesever
  rm -f /etc/yum/vars/releasever
fi

# https://bugs.centos.org/view.php?id=13836#c33128
source /etc/os-release
if [ "${ID}${VERSION_ID}" == "centos7" ]; then
    rm -f /etc/sysconfig/network-scripts/ifcfg-eth0
fi

# Clean resolv.conf if it's not managed by system
if [ "${IS_OFFICIAL_AMI_BUILD}" == "true" ]; then
    echo "Clean resolv.conf for official AMIs"
    echo -n > /etc/resolv.conf
    rm -f /run/systemd/resolve/resolv.conf
fi

find /var/log -type f -exec /bin/rm -v {} \;
touch /var/log/lastlog
