#!/bin/bash

docker run -ti \
    --rm=true \
    --name=chef_configure \
    -v $PWD:/build \
    -v $PWD/tests/dna.json:/etc/chef/dna.json \
    chef-base:latest \
    /bin/bash
