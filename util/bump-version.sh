#!/bin/bash

set -ex

# On Mac OS, the default implementation of sed is BSD sed, but this script requires GNU sed.
if [ "$(uname)" == "Darwin" ]; then
  command -v gsed >/dev/null 2>&1 || { echo >&2 "[ERROR] Mac OS detected: please install GNU sed with 'brew install gnu-sed'"; exit 1; }
  PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
fi

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

sed -i "s/ENV\['KITCHEN_PCLUSTER_VERSION'\] || '${CURRENT_PCLUSTER_VERSION}'/ENV\['KITCHEN_PCLUSTER_VERSION'\] || '${NEW_PCLUSTER_VERSION}'/g" kitchen.ec2.yml

# Update dependencies version in main cookbook metadata
COOKBOOKS=("aws-parallelcluster-common" "aws-parallelcluster-awsbatch" "aws-parallelcluster-config" "aws-parallelcluster-install" "aws-parallelcluster-scheduler-plugin" "aws-parallelcluster-slurm" "aws-parallelcluster-test")
for COOKBOOK in ${COOKBOOKS[*]}
do
  sed -i "s/depends '${COOKBOOK}', '~> ${CURRENT_PCLUSTER_VERSION_SHORT}'/depends '${COOKBOOK}', '~> ${NEW_PCLUSTER_VERSION_SHORT}'/g" metadata.rb
done

# Update version in specific(install, config, ecc...) cookbook metadata
FILES=("cookbooks/aws-parallelcluster-common/metadata.rb" "cookbooks/aws-parallelcluster-awsbatch/metadata.rb" "cookbooks/aws-parallelcluster-config/metadata.rb" "cookbooks/aws-parallelcluster-install/metadata.rb" "cookbooks/aws-parallelcluster-scheduler-plugin/metadata.rb" "cookbooks/aws-parallelcluster-slurm/metadata.rb" "cookbooks/aws-parallelcluster-test/metadata.rb")
sed -i "s/version '${CURRENT_PCLUSTER_VERSION_SHORT}'/version '${NEW_PCLUSTER_VERSION_SHORT}'/g" ${FILES[*]}

# Update dependencies version in specific(install, config, ecc...) cookbook metadata
FILES=("cookbooks/aws-parallelcluster-awsbatch/metadata.rb" "cookbooks/aws-parallelcluster-config/metadata.rb" "cookbooks/aws-parallelcluster-install/metadata.rb" "cookbooks/aws-parallelcluster-scheduler-plugin/metadata.rb" "cookbooks/aws-parallelcluster-slurm/metadata.rb" "cookbooks/aws-parallelcluster-test/metadata.rb")
sed -i "s/depends 'aws-parallelcluster-common', '~> ${CURRENT_PCLUSTER_VERSION_SHORT}'/depends 'aws-parallelcluster-common', '~> ${NEW_PCLUSTER_VERSION_SHORT}'/g" ${FILES[*]}

CURRENT_AWSBATCH_CLI_VERSION=$(sed -ne "s/^default\['cluster'\]\['parallelcluster-awsbatch-cli-version'\] = '\(.*\)'/\1/p" attributes/default.rb)

sed -i "s/default\['cluster'\]\['parallelcluster-awsbatch-cli-version'\] = '${CURRENT_AWSBATCH_CLI_VERSION}'/default['cluster']['parallelcluster-awsbatch-cli-version'] = '${NEW_AWSBATCH_CLI_VERSION}'/g" attributes/default.rb
