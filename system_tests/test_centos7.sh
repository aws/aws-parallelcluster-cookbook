#!/bin/sh

set -e

run_command=$1

if [ "$run_command" = "" ]; then
    run_command=/build/system_tests/systemd
fi

docker build . -t chef-base:centos7 -f system_tests/Dockerfile.centos7

cat system_tests/dna.json | sed 's/\(.*base_os":\).*/\1 "centos7",/' > /tmp/dna.json

docker run -ti \
    --rm=true \
    --name=chef_configure \
    -v $PWD:/build \
    -v /tmp/dna.json:/etc/chef/dna.json \
    chef-base:centos7 \
    $run_command
