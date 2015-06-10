#!/bin/bash

rm -rf ../vendor/cookbooks
berks vendor ../vendor/cookbooks
packer build packer_centos6.json
packer build packer_alinux.json