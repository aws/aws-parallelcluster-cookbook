#!/bin/bash

rm -rf ../vendor/cookbooks
berks vendor ../vendor/cookbooks
export BUILD_DATE=`date +%Y%m%d%H%M`
packer build -var-file=packer_variables.json packer_centos6.json
packer build -var-file=packer_variables.json packer_alinux.json
packer build -var-file=packer_variables.json packer_ubuntu.json