#!/bin/sh

set -e

run_command=$1

if [ "$run_command" = "" ]; then
    run_command=/build/system_tests/systemd
fi

docker build . -t chef-base -f system_tests/Dockerfile

docker run -ti \
    --rm=true \
    --name=chef_configure \
    -v $PWD:/build \
    -v $PWD/system_tests/dna.json:/etc/chef/dna.json \
    chef-base:latest \
    $run_command
