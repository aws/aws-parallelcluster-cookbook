#!/bin/bash

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
    if [ -e $path.bak ]; then
        mv ${path}.bak ${path}
    else
        rm ${path}
    fi
}

cd /tmp/cookbooks
cp /build/test_attributes.rb /tmp/cookbooks/attributes
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

echo "cookbook_path [\"/etc/chef/cookbooks\"]" > /etc/chef/client.rb

mkdir -p /lib/modules/`uname -r`
apt install linux-modules-`uname -r`

chef-client --local-mode --config /etc/chef/client.rb --log_level info --force-formatter --no-color --chef-zero-port 8889 --json-attributes /etc/parallelcluster/image_dna.json --override-runlist aws-parallelcluster::default

# unmock
#rm /usr/local/sbin/modprobe /usr/local/sbin/sysctl /usr/local/sbin/udevadm
