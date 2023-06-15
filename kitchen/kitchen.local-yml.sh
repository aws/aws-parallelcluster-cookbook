#!/bin/bash

KITCHEN_SCOPE=$1; shift;
KITCHEN_SUBJECT=$(echo $KITCHEN_SCOPE | awk -F- '{print $1}')
KITCHEN_PHASE=$(echo $KITCHEN_SCOPE | awk -F- '{print $2}')

if [[ "-recipes-resources-validate-" =~ ${KITCHEN_SUBJECT} ]]; then
  # ./kitchen.$driver.sh recipes-install ... will run kitchen in aws-parallelcluster-cookbook dir
  export KITCHEN_COOKBOOK_PATH='.'
else
  # ./kitchen.$driver.sh platform-install ... will run kitchen in aws-parallelcluster-cookbook/cookbooks/aws-parallelcluster-platform dir
  export KITCHEN_COOKBOOK_PATH="cookbooks/aws-parallelcluster-${KITCHEN_SUBJECT}"
fi

export KITCHEN_LOCAL_YAML="${KITCHEN_COOKBOOK_PATH}/kitchen.${KITCHEN_SCOPE}.yml"
export KITCHEN_PHASE
