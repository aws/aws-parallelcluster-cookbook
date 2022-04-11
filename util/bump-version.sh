#!/bin/bash

set -ex

if [ -z "$1" -o -z "$2" ]; then
    echo "New version not specified. Usage: bump-version.sh NEW_PCLUSTER_VERSION NEW_AWSBATCH_CLI_VERSION"
    exit 1
fi

NEW_PCLUSTER_VERSION=$1
NEW_AWSBATCH_CLI_VERSION=$2

CURRENT_PCLUSTER_VERSION=$(sed -ne "s/default\['cluster'\]\['parallelcluster-version'\] = '\(.*\)'/\1/p" attributes/default.rb)

NEW_PCLUSTER_VERSION_SHORT=$(echo ${NEW_PCLUSTER_VERSION} | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+")
CURRENT_PCLUSTER_VERSION_SHORT=$(echo ${CURRENT_PCLUSTER_VERSION} | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+")

sed -i "s/default\['cluster'\]\['parallelcluster-version'\] = '${CURRENT_PCLUSTER_VERSION}'/default['cluster']['parallelcluster-version'] = '${NEW_PCLUSTER_VERSION}'/g" attributes/default.rb
sed -i "s/default\['cluster'\]\['parallelcluster-cookbook-version'\] = '$CURRENT_PCLUSTER_VERSION'/default['cluster']['parallelcluster-cookbook-version'] = '${NEW_PCLUSTER_VERSION}'/g" attributes/default.rb
sed -i "s/default\['cluster'\]\['parallelcluster-node-version'\] = '${CURRENT_PCLUSTER_VERSION}'/default['cluster']['parallelcluster-node-version'] = '${NEW_PCLUSTER_VERSION}'/g" attributes/default.rb
sed -i "s/version '${CURRENT_PCLUSTER_VERSION_SHORT}'/version '${NEW_PCLUSTER_VERSION_SHORT}'/g" metadata.rb
sed -i "s/depends 'aws-parallelcluster-install', '~> ${CURRENT_PCLUSTER_VERSION_SHORT}'/depends 'aws-parallelcluster-install', '~> ${NEW_PCLUSTER_VERSION_SHORT}'/g" metadata.rb
sed -i "s/depends 'aws-parallelcluster-config', '~> ${CURRENT_PCLUSTER_VERSION_SHORT}'/depends 'aws-parallelcluster-config', '~> ${NEW_PCLUSTER_VERSION_SHORT}'/g" metadata.rb
sed -i "s/depends 'aws-parallelcluster-slurm', '~> ${CURRENT_PCLUSTER_VERSION_SHORT}'/depends 'aws-parallelcluster-slurm', '~> ${NEW_PCLUSTER_VERSION_SHORT}'/g" metadata.rb
sed -i "s/depends 'aws-parallelcluster-scheduler-plugin', '~> ${CURRENT_PCLUSTER_VERSION_SHORT}'/depends 'aws-parallelcluster-scheduler-plugin', '~> ${NEW_PCLUSTER_VERSION_SHORT}'/g" metadata.rb
sed -i "s/depends 'aws-parallelcluster-awsbatch', '~> ${CURRENT_PCLUSTER_VERSION_SHORT}'/depends 'aws-parallelcluster-awsbatch', '~> ${NEW_PCLUSTER_VERSION_SHORT}'/g" metadata.rb
sed -i "s/depends 'aws-parallelcluster-test', '~> ${CURRENT_PCLUSTER_VERSION_SHORT}'/depends 'aws-parallelcluster-test', '~> ${NEW_PCLUSTER_VERSION_SHORT}'/g" metadata.rb
sed -i "s/version '${CURRENT_PCLUSTER_VERSION_SHORT}'/version '${NEW_PCLUSTER_VERSION_SHORT}'/g" cookbooks/aws-parallelcluster-config/metadata.rb
sed -i "s/version '${CURRENT_PCLUSTER_VERSION_SHORT}'/version '${NEW_PCLUSTER_VERSION_SHORT}'/g" cookbooks/aws-parallelcluster-install/metadata.rb
sed -i "s/version '${CURRENT_PCLUSTER_VERSION_SHORT}'/version '${NEW_PCLUSTER_VERSION_SHORT}'/g" cookbooks/aws-parallelcluster-test/metadata.rb
sed -i "s/version '${CURRENT_PCLUSTER_VERSION_SHORT}'/version '${NEW_PCLUSTER_VERSION_SHORT}'/g" cookbooks/aws-parallelcluster-slurm/metadata.rb
sed -i "s/version '${CURRENT_PCLUSTER_VERSION_SHORT}'/version '${NEW_PCLUSTER_VERSION_SHORT}'/g" cookbooks/aws-parallelcluster-scheduler-plugin/metadata.rb
sed -i "s/version '${CURRENT_PCLUSTER_VERSION_SHORT}'/version '${NEW_PCLUSTER_VERSION_SHORT}'/g" cookbooks/aws-parallelcluster-awsbatch/metadata.rb
sed -i "s/aws-parallelcluster-cookbook-.*\"/aws-parallelcluster-cookbook-${NEW_PCLUSTER_VERSION}\"/" system_tests/systemd

CURRENT_AWSBATCH_CLI_VERSION=$(sed -ne "s/^default\['cluster'\]\['parallelcluster-awsbatch-cli-version'\] = '\(.*\)'/\1/p" attributes/default.rb)

sed -i "s/default\['cluster'\]\['parallelcluster-awsbatch-cli-version'\] = '${CURRENT_AWSBATCH_CLI_VERSION}'/default['cluster']['parallelcluster-awsbatch-cli-version'] = '${NEW_AWSBATCH_CLI_VERSION}'/g" attributes/default.rb
