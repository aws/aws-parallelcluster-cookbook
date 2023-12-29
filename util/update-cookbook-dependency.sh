#!/usr/bin/env sh
set -e

# This script updates Cookbook dependencies.
# Usage: update-cookbook-dependencies.sh [PACKAGE] [VERSION]
# Example: update-cookbook-dependencies.sh apt 7.4.0

PACKAGE=$1
VERSION=$2

[[ -z ${PACKAGE} ]] && echo "[ERROR] Missing required argument PACKAGE. Usage: update-cookbook-dependencies.sh [PACKAGE] [VERSION]" && exit 1
[[ -z ${VERSION} ]] && echo "[ERROR] Missing required argument VERSION. Usage: update-cookbook-dependencies.sh [PACKAGE] [VERSION]" && exit 1

# On Mac OS, the default implementation of sed is BSD sed, but this script requires GNU sed.
if [ "$(uname)" == "Darwin" ]; then
  command -v gsed >/dev/null 2>&1 || { echo >&2 "[ERROR] Mac OS detected: please install GNU sed with 'brew install gnu-sed'"; exit 1; }
  PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
fi

echo "[INFO] Updating dependency: ${PACKAGE} ${VERSION}..."

PARALLEL_CLUSTER_COOKBOOK_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )
BERKS_FILE="${PARALLEL_CLUSTER_COOKBOOK_DIR}/Berksfile"
METADATA_FILE="${PARALLEL_CLUSTER_COOKBOOK_DIR}/metadata.rb"
THIRD_PARTY_DIR="${PARALLEL_CLUSTER_COOKBOOK_DIR}/third-party"
DEPENDENCY_DIR="${THIRD_PARTY_DIR}/${PACKAGE}-${VERSION}"
DEPENDENCY_ZIP="${DEPENDENCY_DIR}.tar.gz"
CHEF_REPO_URL="https://github.com/sous-chefs/${PACKAGE}/archive/refs/tags/${VERSION}.tar.gz"

echo "[INFO] Detecting current version of ${PACKAGE}"
CURRENT_VERSION=$(ls ${THIRD_PARTY_DIR} | grep ${PACKAGE} | cut -d '-' -f 2)
if [[ -z ${CURRENT_VERSION} ]]; then
  echo "[ERROR] Cannot find current version of ${PACKAGE}"
  exit 1
else
  echo "[INFO] Current version of ${PACKAGE} is: ${CURRENT_VERSION}"
  if [[ ${VERSION} == ${CURRENT_VERSION} ]]; then
    echo "[WARN] Current version of ${PACKAGE} ${VERSION} already installed. No update required."
    exit 0
  fi
fi

echo "[INFO] Downloading ${PACKAGE} ${VERSION} from Chef Marketplace"
wget -O ${DEPENDENCY_ZIP} ${CHEF_REPO_URL}
mkdir -p ${DEPENDENCY_DIR}
tar xzf ${DEPENDENCY_ZIP} -C ${DEPENDENCY_DIR} --strip-components 1
rm ${DEPENDENCY_ZIP}

METADATA_FILES=(
"${PARALLEL_CLUSTER_COOKBOOK_DIR}/metadata.rb"
"${PARALLEL_CLUSTER_COOKBOOK_DIR}/cookbooks/aws-parallelcluster-awsbatch/metadata.rb"
"${PARALLEL_CLUSTER_COOKBOOK_DIR}/cookbooks/aws-parallelcluster-config/metadata.rb"
"${PARALLEL_CLUSTER_COOKBOOK_DIR}/cookbooks/aws-parallelcluster-install/metadata.rb"
"${PARALLEL_CLUSTER_COOKBOOK_DIR}/cookbooks/aws-parallelcluster-scheduler-plugin/metadata.rb"
"${PARALLEL_CLUSTER_COOKBOOK_DIR}/cookbooks/aws-parallelcluster-slurm/metadata.rb"
"${PARALLEL_CLUSTER_COOKBOOK_DIR}/cookbooks/aws-parallelcluster-scheduler-plugin/metadata.rb"
"${PARALLEL_CLUSTER_COOKBOOK_DIR}/cookbooks/aws-parallelcluster-test/metadata.rb"
)

for metadata_file in ${METADATA_FILES[@]}; do
  echo "[INFO] Updating metadata: ${metadata_file}"
  sed -i "s/depends '${PACKAGE}', '~> ${CURRENT_VERSION}'/depends '${PACKAGE}', '~> ${VERSION}'/" ${metadata_file}
done

echo "[INFO] Updating Berksfile: ${BERKS_FILE}"
sed -i "s/${PACKAGE}-${CURRENT_VERSION}/${PACKAGE}-${VERSION}/" ${BERKS_FILE}

echo "[INFO] Removing previous version of ${PACKAGE} ${CURRENT_VERSION}"
rm -rf "${THIRD_PARTY_DIR}/${PACKAGE}-${CURRENT_VERSION}"

echo "[INFO] Dependency updated: ${PACKAGE} ${VERSION}"
