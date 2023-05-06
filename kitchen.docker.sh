#!/bin/bash

source kitchen.local-yml.sh

THIS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export KITCHEN_YAML="${THIS_DIR}/kitchen.docker.yml"
export KITCHEN_GLOBAL_YAML="${THIS_DIR}/kitchen.global.yml"
export KITCHEN_DRIVER=dokken

echo "** KITCHEN_LOCAL_YAML: $KITCHEN_LOCAL_YAML"
echo "** KITCHEN_YAML: $KITCHEN_YAML"
echo "** KITCHEN_GLOBAL_YAML: $KITCHEN_GLOBAL_YAML"
echo "kitchen $*"

cd "${KITCHEN_COOKBOOK_PATH}" && kitchen "$@"
