#!/bin/bash

docker run -ti \
    --rm=true \
    --name=chef_configure \
    -v $PWD:/build \
    -v $PWD/system_tests/dna.json:/etc/chef/dna.json \
    chef-base:latest \
    /build/system_tests/systemd
