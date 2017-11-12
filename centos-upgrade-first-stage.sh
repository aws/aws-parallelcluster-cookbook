#!/bin/bash

#
# Script to run the first stage (everything through rebooting to flip into
# the new kernel) for upgrading the CentOS AMIs from the imported version
# to the latest in that major release series.
#
# By the time this script was written, CentOS 7.4 had shipped, which
# includes ENA driver by default.  CentOS 6, being ancient, won't
# include such upgrades, so we do that after upgrade (actually,
# centos-upgrade-second-stage does that, so that we don't have to
# guess at what the new default kernel version is).
#

if test "`sed -n '/CentOS release 6\..*/p' /etc/centos-release`" != ""; then
    is_centos6=1
else
    is_centos6=0
fi

if test $is_centos6 -eq 1 -a "`/sbin/lsmod | grep ena`" != "" ; then
    echo "This script is lazy and can not be run on instances which"
    echo "use ENA for networking.  Either update the script or use"
    echo "a non-ENA instance type."
    echo "***** Aborting now *****"
    exit 1
fi

set -e

echo "Enabling epel repo"
sudo yum -y install epel-release

if test $is_centos6 -eq 1; then
    echo "Enabling elrepo repo"
    sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    sudo rpm -Uvh http://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm

    # elrepo by default enables their base repo, but not their kernel
    # repo.  We want to enable the kernel repo, but not the base repo,
    # to match what we've done in previous CfnCluster releases.
    # Rather than some super-ugly sed, just copy an archived repo
    # file.
    sudo cp /tmp/centos6.elrepo.repo /etc/yum.repos.d/elrepo.repo

    # CfnCluster CentOS AMIs have always shipped with the elrepo -lt
    # kernel as the default, but it appears to have been set as the
    # default by hand in grub.conf.  Make the -lt kernel the default
    # in systconfig, so yum upgrade won't revert the default kernel
    # back to the 2.6.32 default kernel.
    echo "Setting kernel-lt as default kernel series"
    sudo /bin/sed -r -i -e 's/^DEFAULTKERNEL=kernel$/DEFAULTKERNEL=kernel-lt/' /etc/sysconfig/kernel || exit $?

    # install the kernel-lt 3.10 kernel to match previous releases
    echo "Installing kernel-lt kernel"
    sudo yum -y install kernel-lt kernel-lt-devel
fi

# Upgrade everything!
echo "Running upgrades!"
sudo yum -y upgrade

echo "Installing basic packages"
sudo yum -y groupinstall development
sudo yum -y install git yum-utils

if test $is_centos6 -eq 1; then
    sudo yum -y install python-pip
    sudo pip install awscli --upgrade
else
    sudo yum -y install python-pip python-wheel awscli
fi

set +e

echo "Disabling SELinux"
sudo /bin/sed -r -i -e 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

echo "Update Complete.  Rebooting."
# sleep for 30 seconds to make sure packer doesn't try to run the next
# step before the reboot happens
sudo reboot ; sleep 30
