#!/usr/bin/env bash
#
# Copyright 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
#
# Developer-only helper: upload this local pcluster-diag source to a running cluster's head node,
# overwriting the content of the node's tool source dir. NOT shipped to nodes (see chefignore).
#
# Usage (from the pcluster-diag directory):
#   ./tools/sync-to-cluster.sh <cluster-name> <region> <ssh-key>

set -euo pipefail

info() { printf 'INFO: %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; }

# Report a clear failure if any step below errors out (set -e triggers this on the failing command).
trap 'fail "sync-to-cluster failed."' ERR

if [ "$#" -ne 3 ]; then
  echo "Usage: $(basename "$0") <cluster-name> <region> <ssh-key>" >&2
  exit 2
fi

CLUSTER_NAME="$1"
REGION="$2"
SSH_KEY="$3"

# The pcluster-diag source root (the parent of this tools/ directory).
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The node source dir the cookbook stages the tool into.
NODE_SOURCE_DIR="/opt/parallelcluster/sources/pcluster-diag"

info "Syncing local pcluster-diag source to cluster '${CLUSTER_NAME}' (${REGION})"

# Resolve the cluster's default OS user from the CloudFormation stack parameter "ClusterUser".
# Capture stdout+stderr so the underlying AWS error is shown if the call fails.
info "Resolving cluster user from CloudFormation stack '${CLUSTER_NAME}'..."
if ! CLUSTER_USER="$(aws cloudformation describe-stacks --stack-name "${CLUSTER_NAME}" --region "${REGION}" \
    --query "Stacks[0].Parameters[?ParameterKey=='ClusterUser'].ParameterValue | [0]" --output text 2>&1)"; then
  fail "Failed to describe CloudFormation stack '${CLUSTER_NAME}':"
  printf '%s\n' "${CLUSTER_USER}" >&2
  exit 1
fi
if [ -z "${CLUSTER_USER}" ] || [ "${CLUSTER_USER}" = "None" ]; then
  fail "Could not determine ClusterUser from CloudFormation stack '${CLUSTER_NAME}'."
  exit 1
fi
info "Cluster user: ${CLUSTER_USER}"

# Resolve the head node IP from the cluster. The pcluster CLI outputs JSON (no --output flag), so
# capture the full document and extract the field with python3; capture stderr to surface failures.
info "Resolving head node IP..."
if ! DESCRIBE_JSON="$(pcluster describe-cluster --cluster-name "${CLUSTER_NAME}" --region "${REGION}" 2>&1)"; then
  fail "Failed to describe cluster '${CLUSTER_NAME}':"
  printf '%s\n' "${DESCRIBE_JSON}" >&2
  exit 1
fi
HEAD_NODE_IP="$(printf '%s' "${DESCRIBE_JSON}" \
  | python3 -c 'import json, sys; print((json.load(sys.stdin).get("headNode") or {}).get("publicIpAddress") or "")')"

if [ -z "${HEAD_NODE_IP}" ] || [ "${HEAD_NODE_IP}" = "None" ]; then
  fail "Could not determine the head node public IP for cluster '${CLUSTER_NAME}'."
  exit 1
fi
info "Head node: ${CLUSTER_USER}@${HEAD_NODE_IP}"

# Upload the local source straight into the node's (root-owned) tool source dir in one step: the
# remote rsync runs under sudo. Honors .gitignore, skips git metadata, and --delete mirrors the tree.
info "Syncing source from ${SOURCE_DIR} into ${NODE_SOURCE_DIR} on the head node..."
rsync -av --filter=':- .gitignore' --exclude='.git' --delete \
  -e "ssh -i ${SSH_KEY}" --rsync-path="sudo rsync" \
  "${SOURCE_DIR}/" "${CLUSTER_USER}@${HEAD_NODE_IP}:${NODE_SOURCE_DIR}/"

info "Success: pcluster-diag source synced on cluster '${CLUSTER_NAME}'. Verify with 'sudo pcluster-diag --version' on the node."
