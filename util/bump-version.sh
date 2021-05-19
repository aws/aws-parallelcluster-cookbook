#!/bin/bash

set -ex

if [ -z "$1" ]; then
    echo "New version not specified. Usage: bump-version.sh NEW_VERSION"
    exit 1
fi

NEW_VERSION=$1
CURRENT_VERSION=$(sed -ne "s/^version '\(.*\)'/\1/p" metadata.rb)

sed -i "s/default\['cluster'\]\['parallelcluster-version'\] = '$CURRENT_VERSION'/default['cluster']['parallelcluster-version'] = '$NEW_VERSION'/g" attributes/default.rb
sed -i "s/default\['cluster'\]\['parallelcluster-cookbook-version'\] = '$CURRENT_VERSION'/default['cluster']['parallelcluster-cookbook-version'] = '$NEW_VERSION'/g" attributes/default.rb
sed -i "s/default\['cluster'\]\['parallelcluster-node-version'\] = '$CURRENT_VERSION'/default['cluster']['parallelcluster-node-version'] = '$NEW_VERSION'/g" attributes/default.rb
sed -i "s/version '$CURRENT_VERSION'/version '$NEW_VERSION'/g" metadata.rb
