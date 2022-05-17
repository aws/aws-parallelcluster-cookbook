#!/bin/bash

set -e

mock_list=()
function premock(){
    path=$1
    mock_list+=($path)
    if [ -e $path ]; then
        cp $path ${path}.bak
    fi
}

function mock(){
    path=$1
    premock $path
    echo -e "#\! /usr/bin/bash" > $path
    chmod +x $path
}

function unmock(){
    path=$1
    for path in "${mock_list[@]}"; do
        if [ -e $path.bak ]; then
            mv ${path}.bak ${path}
        else
            rm ${path}
        fi
    done
}

cd /tmp/cookbooks
cp system_tests/test_attributes.rb ./attributes
mkdir -p /etc/parallelcluster
cp system_tests/image_dna.json /etc/parallelcluster/image_dna.json
LANG=en_US.UTF-8 /opt/cinc/embedded/bin/berks vendor /etc/chef/cookbooks --delete || (echo 'Vendoring cookbook failed.' && exit 1)

# Mock aspects of the system so that recipes run and complete cleanly
mocks=(/etc/init.d/rpc-statd
       /etc/init.d/nfs-config.service
       /usr/local/bin/udevadm
       /usr/local/sbin/sysctl
       /usr/local/sbin/modprobe)

for mock_path in "${mocks[@]}"; do
    mock $mock_path
done

premock /sbin/chkconfig
premock /bin/systemctl
cp system_tests/chkconfig /sbin/chkconfig
cp system_tests/systemctl /bin/systemctl

echo "cookbook_path [\"/etc/chef/cookbooks\"]" > /etc/chef/client.rb

mkdir -p /lib/modules/${KERNEL_RELEASE}

platform=$(cat /etc/*-release | grep ID_LIKE | sed 's/.*=//')

if [ "$platform" == "debian" ]; then
    apt install -y linux-modules-${KERNEL_RELEASE}
else
    yum install -y kernel-modules
fi

cinc-client --local-mode --config /etc/chef/client.rb --log_level info --force-formatter --no-color --chef-zero-port 8889 --json-attributes /etc/parallelcluster/image_dna.json --override-runlist aws-parallelcluster::default

# disabling unmocking for configuration run
# unmock
