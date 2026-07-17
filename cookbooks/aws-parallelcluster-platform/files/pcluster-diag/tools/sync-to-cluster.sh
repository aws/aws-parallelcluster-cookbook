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
# overwriting the content of the node's tool source dir. It also (re)installs the `pcluster-diag`
# wrapper on PATH so the synced source is runnable as `pcluster-diag`. NOT shipped to nodes (see
# chefignore).
#
# Usage (from the pcluster-diag directory):
#   ./tools/sync-to-cluster.sh <cluster-name> <region> <ssh-key>

set -euo pipefail

info() { printf 'INFO: %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

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

# The wrapper on PATH the cookbook installs (see recipes/install/pcluster_diag.rb), and the glob that
# resolves the cookbook_virtualenv the wrapper runs the tool with.
NODE_BIN_PATH="/usr/local/bin/pcluster-diag"
COOKBOOK_VIRTUALENV_GLOB="/opt/parallelcluster/pyenv/versions/*/envs/cookbook_virtualenv"

# The cookbook's wrapper template (the single source of truth for the wrapper), rendered here by
# injecting the same variables the recipe passes to it (see recipes/install/pcluster_diag.rb).
WRAPPER_TEMPLATE="${SOURCE_DIR}/../../templates/pcluster-diag/pcluster-diag.erb"

info "Syncing local pcluster-diag source to cluster '${CLUSTER_NAME}' (${REGION})"

# Resolve the cluster's default OS user from the CloudFormation stack parameter "ClusterUser".
# Capture stdout+stderr so the underlying AWS error is shown if the call fails.
info "Resolving cluster user from CloudFormation stack '${CLUSTER_NAME}'..."
if ! CLUSTER_USER="$(aws cloudformation describe-stacks --stack-name "${CLUSTER_NAME}" --region "${REGION}" \
    --query "Stacks[0].Parameters[?ParameterKey=='ClusterUser'].ParameterValue | [0]" --output text 2>&1)"; then
  fail "Failed to describe CloudFormation stack '${CLUSTER_NAME}': ${CLUSTER_USER}"
fi
if [ -z "${CLUSTER_USER}" ] || [ "${CLUSTER_USER}" = "None" ]; then
  fail "Could not determine ClusterUser from CloudFormation stack '${CLUSTER_NAME}'."
fi
info "Cluster user: ${CLUSTER_USER}"

# Resolve the head node IP from the cluster. The pcluster CLI outputs JSON (no --output flag), so
# capture the full document and extract the field with python3; capture stderr to surface failures.
info "Resolving head node IP..."
if ! DESCRIBE_JSON="$(pcluster describe-cluster --cluster-name "${CLUSTER_NAME}" --region "${REGION}" 2>&1)"; then
  fail "Failed to describe cluster '${CLUSTER_NAME}': ${DESCRIBE_JSON}"
fi
HEAD_NODE_IP="$(printf '%s' "${DESCRIBE_JSON}" \
  | python3 -c 'import json, sys; print((json.load(sys.stdin).get("headNode") or {}).get("publicIpAddress") or "")')"

if [ -z "${HEAD_NODE_IP}" ] || [ "${HEAD_NODE_IP}" = "None" ]; then
  fail "Could not determine the head node public IP for cluster '${CLUSTER_NAME}'."
fi
info "Head node: ${CLUSTER_USER}@${HEAD_NODE_IP}"

# Upload the local source straight into the node's (root-owned) tool source dir in one step: the
# remote rsync runs under sudo. Honors .gitignore, skips git metadata, and --delete mirrors the tree.
info "Syncing source from ${SOURCE_DIR} into ${NODE_SOURCE_DIR} on the head node..."
rsync -av --filter=':- .gitignore' --exclude='.git' --delete \
  -e "ssh -i ${SSH_KEY}" --rsync-path="sudo rsync" \
  "${SOURCE_DIR}/" "${CLUSTER_USER}@${HEAD_NODE_IP}:${NODE_SOURCE_DIR}/"

# Install the PATH wrapper so the synced source is runnable as `pcluster-diag`. It is always
# (re)written, overwriting any existing wrapper. The wrapper is rendered from the cookbook's own
# template (the single source of truth) by injecting the two variables the recipe supplies: the node
# source dir and the cookbook_virtualenv path.
info "Installing the pcluster-diag wrapper at ${NODE_BIN_PATH} on the head node..."
if [ ! -f "${WRAPPER_TEMPLATE}" ]; then
  fail "Could not find the wrapper template at ${WRAPPER_TEMPLATE}."
fi

# Resolve the cookbook_virtualenv path the wrapper must run. The glob expands remotely (kept literal
# in the local command string).
VIRTUALENV_PATH="$(ssh -i "${SSH_KEY}" "${CLUSTER_USER}@${HEAD_NODE_IP}" \
  "ls -d ${COOKBOOK_VIRTUALENV_GLOB} 2>/dev/null | head -n1")"
if [ -z "${VIRTUALENV_PATH}" ]; then
  fail "Could not locate the cookbook_virtualenv (${COOKBOOK_VIRTUALENV_GLOB}) on the node."
fi

info "Installing wrapper from ${WRAPPER_TEMPLATE} (interpreter: ${VIRTUALENV_PATH})..."
# Render the ERB template by substituting the variables it declares, then install it under sudo.
sed -e "s|<%=[[:space:]]*@source_dir[[:space:]]*%>|${NODE_SOURCE_DIR}|g" \
    -e "s|<%=[[:space:]]*@virtualenv_path[[:space:]]*%>|${VIRTUALENV_PATH}|g" \
    "${WRAPPER_TEMPLATE}" \
  | ssh -i "${SSH_KEY}" "${CLUSTER_USER}@${HEAD_NODE_IP}" \
      "sudo tee '${NODE_BIN_PATH}' >/dev/null && sudo chmod 0744 '${NODE_BIN_PATH}'"
info "Wrapper installed at ${NODE_BIN_PATH}."

info "Success: pcluster-diag source synced on cluster '${CLUSTER_NAME}'. Verify with 'sudo pcluster-diag --version' on the node."
