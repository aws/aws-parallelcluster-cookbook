#!/bin/bash
# Copyright 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# GPU Health Check
# Check GPU healthiness by executing NVIDIA DCGM diagnostic tool
# The diagnostic check targets only the GPUs allocated to the job, listed by Slurm in SLURM_JOB_GPUS: the GPUs requested
# through GRES, or all the GPUs of the node with an exclusive node allocation. No other job can use them, so the
# diagnostic does not interfere with other jobs. If the job has no GPU allocated, the check is skipped.
# Prerequisite for the diagnostic check are:
#   * node has NVIDIA GPU
#   * fabric manager service is running (if node is NVSwitch enabled)
#   * persistent mode is enabled for the target GPU
# The diagnostic check does not need the DCGM service. Without it, checks of concurrent jobs can run on their own GPUs
# at the same time. With it, DCGM allows only one diagnostic per node, so a check that would run concurrently with
# another one is skipped.

## DCGMI run level
# 1 - Quick (System Validation)
# 2 - Medium (Extended System Validation)
# 3 - Long (System HW Diagnostics)
# 4 - Extended (Longer-running System HW Diagnostics)
DCGMI_LEVEL=2

## Lock held by the check running a diagnostic while the DCGM service is running
DCGM_SERVICE_LOCK_FILE=/var/lock/gpu_health_check_dcgm.lock

## Exit code of dcgmi diag when another diagnostic is running through the DCGM service on the node:
## "Return: (-34) : The requested operation could not be completed because the affected resource is in use"
DCGMI_DIAG_RESOURCE_IN_USE_EXIT_CODE=222

function main() {

  ## Identify full path of lspci command
  lspci_fullpath=$(PATH=$PATH:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/bin command -v lspci)

  ## Check if the instance has an NVIDIA acceleration
  is_nvidia
  fast_success_exit "$?" "The GPU Health Check is running in an instance without a supported GPU: skipping its execution."

  ## Check if the nvidia-smi command is available
  command -v nvidia-smi &>/dev/null
  fast_success_exit "$?" "The GPU Health Check has been executed but the nvidia-smi tool is not available in this system or is located in a different file path. Please consider using an official ParallelCluster AMI."

  ## Check if the DCGM Diagnostic tool is available
  command -v dcgmi  &>/dev/null
  fast_success_exit "$?" "The GPU Health Check has been executed but the NVIDIA DCGM Diagnostic tool is not available in this system or is located in a different file path. Please consider using an official ParallelCluster AMI."

  ## Check if the NVIDIA GPU is supported by DCGM tool
  ## The "nvidia-smi -L" return the list of GPUs available on the node:
  ## $nvidia-smi -L
  ## GPU 0: NVIDIA A100-SXM4-40GB (UUID: GPU-...)
  ## GPU 1: NVIDIA A100-SXM4-40GB (UUID: GPU-...)
  ##     MIG 1g.10gb     Device  1: (UUID: MIG-...)
  nvidia_smi_output=$(nvidia-smi -L)
  fast_success_exit "$?" "The nvidia-smi tool failed its execution."
  log_info "GPU list is '${nvidia_smi_output//$'\n'/, }'"
  is_dcgm_supported
  fast_success_exit "$?" "The GPU Health Check is running in a NVIDIA GPU not supported by DCGM Diagnostic tool: skipping its execution."

  ## Select the GPUs to check: only GPUs that no other job can use
  select_target_gpus
  fast_success_exit "$?" "Skipping execution of the GPU Health Check"
  log_info "The value of GPU_DEVICE_ORDINAL is '${GPU_DEVICE_ORDINAL}'"

  ## If the DCGM service is running, allow only one diagnostic at a time on the node
  acquire_dcgm_service_lock
  fast_success_exit "$?" "Skipping execution of the GPU Health Check"

  ## Services Initialization
  local nvidia_fabricmanager_service_started
  initialize_nvidia_fabricmanager
  fast_success_exit "$?" "Skipping execution of the GPU Health Check"

  ## Retrieve gpus information and enable them to run the health check
  local gpus_list
  gpus_list=${GPU_DEVICE_ORDINAL//,/$'\n'}
  for gpu_id in $gpus_list
  do
    # Retrieve gpu information. This check will exit in following cases:
    # - the nvidia-smi command is not available
    # - the nvidia-smi command is available but it fails its execution
    nvidia_smi_out=$(nvidia-smi -q -i $gpu_id)
    fast_success_exit "$?" "The nvidia-smi tool failed its execution."

    ## Enable persistence mode in target GPU, required by the DCGM Diagnostic tool
    local persistence_mode_enabled_$gpu_id
    persistence_mode=$(echo "$nvidia_smi_out" | grep "Persistence Mode")
    if [[ ! ${persistence_mode} == *"Enabled"* ]]; then
      nvidia-smi -i $gpu_id -pm 1 >/dev/null
      log_info "Persistence mode has been enabled by the GPU Health Check in target GPU '${gpu_id}'"
      declare persistence_mode_enabled_$gpu_id=true
    else
      log_info "Persistence mode already enabled for target GPU '${gpu_id}'"
    fi

    ## Log useful GPU information
    gpu_identifier=$(echo "$nvidia_smi_out" | grep "^GPU " | xargs)
    gpu_uuid=$(echo "$nvidia_smi_out" | grep "GPU UUID" | xargs)
    gpu_serial_number=$(echo "$nvidia_smi_out" | grep "Serial Number" | xargs)
    # This command logs the GPU information in the format
    # Details for GPU '0'. 'GPU 00000000:00:1E.0', 'GPU UUID : GPU-931c0765-01f6-f7af-00df-fb4202cec8b9', 'Serial Number : 0322817127524'
    log_info "Details for GPU '${gpu_id}': '${gpu_identifier}', '${gpu_uuid}', '${gpu_serial_number}'"
  done

  ## Run GPUs Health Check test
  log_info "Running GPU Health Check with DCGMI level $DCGMI_LEVEL"

  parameters=""
  if [[ $nvidia_smi_out =~ "NVIDIA L4" ]]; then
    parameters="-p pcie.h2d_d2h_single_pinned.min_pci_width=8;pcie.h2d_d2h_single_unpinned.min_pci_width=8"
  fi

  dcgmi diag -i $GPU_DEVICE_ORDINAL -r $DCGMI_LEVEL $parameters
  dcgmi_exit_code=$?

  ## The DCGM service may have been started after acquire_dcgm_service_lock, and another check may be running a
  ## diagnostic through it: this does not mean the GPUs are unhealthy, so the check is skipped.
  if [ $dcgmi_exit_code -eq $DCGMI_DIAG_RESOURCE_IN_USE_EXIT_CODE ]; then
    log_warning "Another DCGM diagnostic is already running on the node: skipping execution of the GPU Health Check"
    tear_down
    return 0
  fi

  if [ $dcgmi_exit_code -ne 0 ]; then
    log_error "The GPU Health Check failed"
  else
    log_info "The GPU Health Check succeeded"
  fi
  tear_down
  return $dcgmi_exit_code
}

function _log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S,%3N") - [${0##*/}] - $1 - JobID $SLURM_JOB_ID - ${*:2}"
}

function log_info() {
  _log "INFO" "$@"
}

function log_warning() {
  _log "WARNING" "$@"
}

function log_error() {
  _log "ERROR" "$@"
}

function fast_success_exit() {
  if [ $1 -ne 0 ]; then
    log_info "$2"
    tear_down
    exit 0
  fi
}

function is_nvidia() {
  $lspci_fullpath | grep -i -o 'NVIDIA' &>/dev/null
  return $?
}

function is_dcgm_supported() {
  ## DCGM Diagnostic is not supported on K520 GPUs
  if ! echo $nvidia_smi_output | grep -v -i -o ' K520 ' &>/dev/null; then
    log_info "K520 GPU detected on the node: DCGM Diagnostic is not supported."
    return 1
  fi

  ## DCGM Diagnostic is not supported when MIG is enabled on any GPU on the node (verified up to DCGM 4.5.3).
  if is_mig_enabled; then
    log_info "MIG detected on at least one GPU on the node: DCGM Diagnostic is not supported."
    return 1
  fi

  return 0
}

function is_mig_enabled() {
  ## Returns 0 (true) if MIG mode is enabled on at least one GPU on the node, non-zero otherwise.
  nvidia-smi --query-gpu=mig.mode.current --format=csv,noheader | grep -qi "Enabled"
}

function start_service() {
  systemctl start $1
  if [ $? -ne 0 ]; then
    log_info "Unable to start service $1"
    return 1
  fi
}

function select_target_gpus() {
  log_info "Selecting the GPUs to check from SLURM_JOB_GPUS='${SLURM_JOB_GPUS}'"

  ## Slurm sets SLURM_JOB_GPUS to the GPUs allocated to the job: the GPUs requested through GRES, or all the GPUs of
  ## the node with an exclusive node allocation.
  if [ -n "$SLURM_JOB_GPUS" ]; then
    GPU_DEVICE_ORDINAL=$SLURM_JOB_GPUS
    log_info "Checking the GPUs allocated to the job"
    return 0
  fi

  ## Otherwise other jobs can use any GPU of the node, and the diagnostic would interfere with them.
  log_info "The job has no GPU allocated"
  return 1
}

function acquire_dcgm_service_lock() {
  ## The DCGM service allows only one diagnostic per node: if the service is running, the check runs only if no other
  ## check is running a diagnostic. The lock is released when the check exits.
  systemctl show nvidia-dcgm.service -p ActiveState | grep "=active"
  if [ $? -eq 0 ]; then
    log_info "nvidia-dcgm service is running: only one GPU Health Check can run at a time on the node"
    exec 9>"${DCGM_SERVICE_LOCK_FILE}"
    flock -n 9
    if [ $? -ne 0 ]; then
      log_warning "Another GPU Health Check is running on the node while the nvidia-dcgm service is running." \
        "Stop the nvidia-dcgm service to allow GPU Health Checks of concurrent jobs to run."
      return 1
    fi
  fi
}

function initialize_nvidia_fabricmanager() {
  log_info "Verifying if the check is running on a NVSwitch enabled system"
  nvswitch_check=$($lspci_fullpath -d 10de:1af1 | wc -l)
  if [ "${nvswitch_check}" -gt 1 ]; then
    systemctl show nvidia-fabricmanager.service -p ActiveState | grep "=active"
    if [ $? -ne 0 ]; then
      log_info "Starting nvidia-fabricmanager since it is not running"
      start_service nvidia-fabricmanager
      if [ $? -ne 0 ]; then
        return 1
      fi
      nvidia_fabricmanager_service_started=true
    else
      log_info "nvidia-fabricmanager is already running"
    fi
  fi
}

function tear_down() {
  log_info "Restoring previous configurations"

  ## Restore previous persistence mode
  for gpu_id in $gpus_list
  do
      persistence_mode_variable=persistence_mode_enabled_$gpu_id
      if [ "${!persistence_mode_variable}" = true ] ; then
        log_info "Disabling persistence mode on GPU '$gpu_id'"
        nvidia-smi -i $gpu_id -pm 0 >/dev/null
      fi
  done

  ## The nvidia-fabricmanager service started by the check is left running, since checks of concurrent jobs may use it.
  if [ "$nvidia_fabricmanager_service_started" = true ] ; then
    log_info "Leaving running the nvidia-fabricmanager service, which may be used by GPU Health Checks of concurrent jobs"
  fi
}

main "$@"
