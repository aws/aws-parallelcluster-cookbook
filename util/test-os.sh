#!/bin/bash
# This script simplifies run of kitchen tests for a given OS.
# It must be executed from the root folder of the cookbook repo:
# bash util/test-os.sh ec2 rhel8
#
# It searches for all the test suites defined in the functional cookbook and runs them sequentially.
# The output will be saved into a `/tmp/kitchen-<os>-<date>` folder.
# To run config tests is required to set a KITCHEN_${os}_AMI environment variable (e.g. KITCHEN_RHEL8_AMI)
# or have a ParallelCluster AMI in the account.

[ -z "$1" ] && echo "Missing driver parameter, should be ec2 or docker" && exit 1
[ -z "$2" ] && echo "Missing OS parameter" && exit 1
driver=$1
os=$2

this_dir=$( cd -- "$(dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
date=$(date +"%Y%m%dT%H%M")
test_output="/tmp/kitchen-${os}-${date}"
mkdir -p "${test_output}"

for dir in "${this_dir}/../cookbooks/aws-parallelcluster-"*/; do
  config_files=$(ls "${dir}"*.yml)
  if [[ -n ${config_files} ]]; then
    for config_file in ${config_files}; do
      filename=$(basename "${config_file}")
      cookbook=$(basename "$(dirname ${config_file})")
      kitchen_config=$(echo "${filename}" | sed "s/kitchen\.\(.*\)\.yml/\1/")
      echo "*** Executing tests in the ${kitchen_config} file"

      ami_env_var=$(echo "KITCHEN_${os}_AMI" | tr '[:lower:]' '[:upper:]')
      if [[ "${kitchen_config}" == *"-config" ]] && [[ -z ${!ami_env_var} ]]; then
        echo "Environment variable ${ami_env_var} not set, skipping ${kitchen_config} test. Look at image_search on kitchen.ec2.yml for more details."
        continue
      fi

      suites=$(yq e '.suites[].name' "${this_dir}/../cookbooks/${cookbook}/kitchen.${kitchen_config}.yml")
      for suite in ${suites}; do
          test="${suite//_/-}-${os}"
          echo "* Executing ${test}"
          bash "${this_dir}/../kitchen.${driver}.sh" "${kitchen_config}" test "${test}" | tee "${test_output}/kitchen-test-${driver}-${kitchen_config}-${test}.txt"
      done
    done
  fi
done
