#!/bin/bash

#
# Script to run the second stage (everything after rebooting into the
# newest kernel) for upgrading the CenOS AMIs from the imported
# version to the latest in that major release series.
#

if test "`sed -n '/CentOS release 6\..*/p' /etc/centos-release`" != ""; then
    is_centos6=1
else
    is_centos6=0
fi

if ! sudo modprobe ena; then
    set -e

    # upgrade to latest ENA
    echo "Installing ENA module"

    echo "Getting ENA source"
    git clone https://github.com/amzn/amzn-drivers.git
    cd amzn-drivers
    git checkout ena_linux_1.3.0

    echo "Building ENA source"
    BUILD_KERNEL=`uname -r`
    cd kernel/linux/ena
    make

    echo "Installing ENA source"
    sudo make -C /lib/modules/${BUILD_KERNEL}/build M=`pwd` modules_install
    sudo depmod -a

    set +e
else
    echo "Not installing ENA module"
fi

echo "Cleaning out old kernels"
sudo package-cleanup -y --oldkernels --count=1

echo "Cleaning up filesystem"
sudo rm -rf /tmp/* /var/tmp/* /var/log/* /etc/ssh/ssh_host*
sudo rm -rf /root/* /root/.ssh /root/.history /root/.bash_history
sudo rm -rf ~/* ~/.ssh ~/.history ~/.bash_history ~/.cache

echo "All done!"
