#!/bin/bash

set -ex

# On Mac OS, the default implementation of sed is BSD sed, but this script requires GNU sed.
if [ "$(uname)" == "Darwin" ]; then
  command -v gsed >/dev/null 2>&1 || { echo >&2 "[ERROR] Mac OS detected: please install GNU sed with 'brew install gnu-sed'"; exit 1; }
  PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
fi

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "New version not specified. Usage: bump-version.sh NEW_PCLUSTER_VERSION NEW_AWSBATCH_CLI_VERSION"
    exit 1
fi

NEW_PCLUSTER_VERSION=$1
NEW_AWSBATCH_CLI_VERSION=$2
VERSIONS_FILE="cookbooks/aws-parallelcluster-shared/attributes/versions.rb"

CURRENT_PCLUSTER_VERSION=$(sed -ne "s/default\['cluster'\]\['parallelcluster-version'\] = '\(.*\)'/\1/p" ${VERSIONS_FILE})

NEW_PCLUSTER_VERSION_SHORT=$(echo ${NEW_PCLUSTER_VERSION} | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+")
CURRENT_PCLUSTER_VERSION_SHORT=$(echo ${CURRENT_PCLUSTER_VERSION} | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+")

sed -i "s/default\['cluster'\]\['parallelcluster-version'\] = '${CURRENT_PCLUSTER_VERSION}'/default['cluster']['parallelcluster-version'] = '${NEW_PCLUSTER_VERSION}'/g" ${VERSIONS_FILE}
sed -i "s/default\['cluster'\]\['parallelcluster-cookbook-version'\] = '$CURRENT_PCLUSTER_VERSION'/default['cluster']['parallelcluster-cookbook-version'] = '${NEW_PCLUSTER_VERSION}'/g" ${VERSIONS_FILE}
sed -i "s/default\['cluster'\]\['parallelcluster-node-version'\] = '${CURRENT_PCLUSTER_VERSION}'/default['cluster']['parallelcluster-node-version'] = '${NEW_PCLUSTER_VERSION}'/g" ${VERSIONS_FILE}
sed -i "s/version '${CURRENT_PCLUSTER_VERSION_SHORT}'/version '${NEW_PCLUSTER_VERSION_SHORT}'/g" metadata.rb

sed -i "s/ENV\['KITCHEN_PCLUSTER_VERSION'\] || '${CURRENT_PCLUSTER_VERSION}'/ENV\['KITCHEN_PCLUSTER_VERSION'\] || '${NEW_PCLUSTER_VERSION}'/g" kitchen.ec2.yml

COOKBOOKS=("aws-parallelcluster-awsbatch" "aws-parallelcluster-entrypoints" "aws-parallelcluster-slurm" "aws-parallelcluster-platform" "aws-parallelcluster-environment" "aws-parallelcluster-computefleet" "aws-parallelcluster-shared" "aws-parallelcluster-slurm" "aws-parallelcluster-tests")
for cookbook in "${COOKBOOKS[@]}"; do
  METADATA_FILES+=("cookbooks/${cookbook}/metadata.rb")
done

# Update version in specific cookbook metadata
sed -i "s/version '${CURRENT_PCLUSTER_VERSION_SHORT}'/version '${NEW_PCLUSTER_VERSION_SHORT}'/g" "${METADATA_FILES[@]}"

for COOKBOOK in "${COOKBOOKS[@]}"; do
  # Update dependencies version in main cookbook metadata
  sed -i "s/depends '${COOKBOOK}', '~> ${CURRENT_PCLUSTER_VERSION_SHORT}'/depends '${COOKBOOK}', '~> ${NEW_PCLUSTER_VERSION_SHORT}'/g" metadata.rb
  # Update dependencies version in specific cookbook metadata
  sed -i "s/depends '${COOKBOOK}', '~> ${CURRENT_PCLUSTER_VERSION_SHORT}'/depends '${COOKBOOK}', '~> ${NEW_PCLUSTER_VERSION_SHORT}'/g" "${METADATA_FILES[@]}"
done

# Update AWS Batch CLI version
CURRENT_AWSBATCH_CLI_VERSION=$(sed -ne "s/^default\['cluster'\]\['parallelcluster-awsbatch-cli-version'\] = '\(.*\)'/\1/p" ${VERSIONS_FILE})
sed -i "s/default\['cluster'\]\['parallelcluster-awsbatch-cli-version'\] = '${CURRENT_AWSBATCH_CLI_VERSION}'/default['cluster']['parallelcluster-awsbatch-cli-version'] = '${NEW_AWSBATCH_CLI_VERSION}'/g" ${VERSIONS_FILE}
