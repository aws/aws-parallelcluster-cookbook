#!/bin/bash

rm -rf ../vendor/cookbooks
berks vendor ../vendor/cookbooks
packer build packer.json