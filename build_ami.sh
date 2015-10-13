#!/bin/bash

rm -rf ../vendor/cookbooks
berks vendor ../vendor/cookbooks
packer build -var-file=packer_variables.json packer_centos6.json
packer build -var-file=packer_variables.json packer_alinux.json