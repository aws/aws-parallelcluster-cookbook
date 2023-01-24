#!/bin/bash

# Run tests as follows:
# ./kitchen.docker.sh <context> <kitchen options>
# where <context> is either recipes or resources.
#
# For instance:
# ./kitchen.docker.sh recipes list
# ./kitchen.docker.sh recipes test ephemeral-drives-setup -c 5 -l debug

export KITCHEN_LOCAL_YAML="kitchen.$1.yml"; shift;
export KITCHEN_YAML=../../kitchen.docker.yml
export KITCHEN_GLOBAL_YAML=../../kitchen.global.yml

kitchen "$@"
