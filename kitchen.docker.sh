#!/bin/bash

export KITCHEN_LOCAL_YAML="kitchen.$1.yml"; shift;
export KITCHEN_YAML=kitchen.docker.yml
export KITCHEN_GLOBAL_YAML=kitchen.global.yml

kitchen "$@"
