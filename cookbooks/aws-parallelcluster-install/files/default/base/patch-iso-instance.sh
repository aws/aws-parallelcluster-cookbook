#!/bin/bash
set -ex

# This script is used to configure instance so that it works as expected in US isolated regions.
# The script supports the configuration for Amazon Linux 2 only.
# Furthermore, the script fails if the provided region is not a US isolated region.
#
# Usage:   ./patch-iso-instance.sh REGION_NAME
# Example: ./patch-iso-instance.sh us-isob-east-1

REGION="${1}"

[[ -z ${REGION} ]] && echo "[ERROR] Missing required argument: REGION" && exit 1
[[ ${REGION} != us-iso* ]] && echo "[ERROR] The specified region '${REGION}' is not a US isolated region" && exit 1

source /etc/os-release
OS="${ID}${VERSION_ID}"
[[ "${OS}" != "amzn2" ]] && echo "[ERROR] Unsupported OS '${OS}'. Configuration supported only on Amazon Linux 2." && exit 1

echo "[INFO] Starting: instance configuration for US isolated region"

REPOSITORY_DEFINITION_FILE="/etc/yum.repos.d/tmp-amzn2-iso.repo"

cat > ${REPOSITORY_DEFINITION_FILE} <<REPO_DEFINITION
[amzn2-iso]
name=Amazon Linux 2 isolated region repository
mirrorlist=http://amazonlinux.\$awsregion.\$awsdomain/\$releasever/core-\$awsregion/latest/\$basearch/mirror.list
priority=9
gpgcheck=0
enabled=1
metadata_expire=300
mirrorlist_expire=300
report_instanceid=yes
REPO_DEFINITION

yum --disablerepo="*" --enablerepo="amzn2-iso" install -y "*-${REGION}"
rm -f ${REPOSITORY_DEFINITION_FILE}
yum --disablerepo="*" --enablerepo="amzn2-*" --security -y update

echo "[INFO] Complete: instance configuration for US isolated region"
