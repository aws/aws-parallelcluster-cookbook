#!/bin/bash

set -ex

if [ -z "$1" ]; then
    echo "New version not specified. Usage: bump-version.sh NEW_VERSION"
    exit 1
fi

NEW_VERSION=$1
CURRENT_VERSION=$(sed -ne "s/^version '\(.*\)'/\1/p" metadata.rb)

sed -i -e "s/\(.*parallelcluster.*version.*\)$CURRENT_VERSION\(.*\)/\1$NEW_VERSION\2/g" amis/packer_variables.json
sed -i "s/default\['cfncluster'\]\['cfncluster-version'\] = '$CURRENT_VERSION'/default['cfncluster']['cfncluster-version'] = '$NEW_VERSION'/g" attributes/default.rb
sed -i "s/default\['cfncluster'\]\['cfncluster-node-version'\] = '$CURRENT_VERSION'/default['cfncluster']['cfncluster-node-version'] = '$NEW_VERSION'/g" attributes/default.rb
sed -i "s/version '$CURRENT_VERSION'/version '$NEW_VERSION'/g" metadata.rb
