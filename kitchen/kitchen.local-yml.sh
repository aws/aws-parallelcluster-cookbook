#!/bin/bash

KITCHEN_SCOPE=$1; shift;
KITCHEN_SUBJECT=$(echo $KITCHEN_SCOPE | awk -F- '{print $1}')
KITCHEN_PHASE=$(echo $KITCHEN_SCOPE | awk -F- '{print $2}')

# ./kitchen.$driver.sh platform-install ... will run kitchen in aws-parallelcluster-cookbook/cookbooks/aws-parallelcluster-platform dir
export KITCHEN_COOKBOOK_PATH="cookbooks/aws-parallelcluster-${KITCHEN_SUBJECT}"

export KITCHEN_LOCAL_YAML="${KITCHEN_COOKBOOK_PATH}/kitchen.${KITCHEN_SCOPE}.yml"
export KITCHEN_PHASE
