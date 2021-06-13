#!/bin/bash
set -e
#
# Manage the access to IMDS
#
# --allow <user1,...,userN>   List of users to allow access to IMDS
# --deny  <user1,...,userN>   List of users to deny access to IMDS
# --unset <user1,...,userN>   Remove iptables rules related to IMDS for the given list of users
# --flush                     Restore default IMDS access
# --help                      Print this help message

function error() {
  >&2 echo "[ERROR] $1"
  exit 1
}

function info() {
  echo "[INFO] $1"
}

function help() {
  local -- cmd=$(basename "$0")
  cat <<EOF

  Usage: ${cmd} [OPTION]...

  Manage the access to IMDS

  --allow <user1,...,userN>   Allow IMDS access to the given list of users
  --deny  <user1,...,userN>   Deny IMDS access to the given list of users
  --unset <user1,...,userN>   Remove iptables rules related to IMDS for the given list of users
  --flush                     Restore default IMDS access
  --help                      Print this help message
EOF
}

function iptables_delete() {
  local chain=$1
  local destination=$2
  local jump=$3
  local user=$4

  # Build iptables delete command
  if [[ -z $user ]]; then
    rule_args="$chain --destination $destination -j $jump"
  else
    rule_args="$chain --destination $destination -j $jump -m owner --uid-owner $user"
  fi

  local iptables_delete_command="iptables -D $rule_args"

  # Remove rules
  local should_remove=true
  while $should_remove; do
    eval $iptables_delete_command 1>/dev/null 2>/dev/null || should_remove=false
  done
}

function iptables_add() {
  local chain=$1
  local destination=$2
  local jump=$3
  local user=$4

  # Remove duplicate rules
  iptables_delete $chain $destination $jump $user

  # Remove opposite rules
  if [[ $jump == "ACCEPT" ]]; then
    iptables_delete $destination "REJECT" $user
  elif [[ $jump == "REJECT" ]]; then
    iptables_delete $destination "ACCEPT" $user
  fi

  # Build iptables add command
  if [[ -z $user ]]; then
    rule_args="$chain --destination $destination -j $jump"
  else
    rule_args="$chain --destination $destination -j $jump -m owner --uid-owner $user"
  fi

  local iptables_add_command="iptables -A $rule_args"

  # Add rule
  eval $iptables_add_command
  info "Rule in chain $chain: $destination $jump $user"
}

function setup_chain() {
  local chain=$1
  local source_chain=$2
  local destination=$3

  iptables --new $chain 2>/dev/null && info "ParallelCluster chain created: $chain" \
  || info "ParallelCluster chain exists: $chain"

  iptables_add $source_chain $destination $chain
}

main() {
  # Constants
  PARALLELCLUSTER_CHAIN="PARALLELCLUSTER_IMDS"
  OUTPUT_CHAIN="OUTPUT"
  IMDS_IP="169.254.169.254"

  # Parse options
  while [ $# -gt 0 ] ; do
      case "$1" in
          --allow)    allow_users="$2"; shift;;
          --deny)     deny_users="$2"; shift;;
          --unset)    unset_users="$2"; shift;;
          --flush)    flush="true";;
          --help)     help; exit 0;;
          *)          help; error "Unrecognized option '$1'";;
      esac
      shift
  done

  # Check required commands
  command -v iptables >/dev/null || error "Cannot find required command: iptables"

  # Check arguments and options
  if [[ -z $allow_users && -z $deny_users && -z $unset_users && -z $flush ]]; then
    error "Missing at least one mandatory option: '--allow', '--deny', '--unset', '--flush'"
  fi

  # Setup ParallelCluster chain
  setup_chain $PARALLELCLUSTER_CHAIN $OUTPUT_CHAIN $IMDS_IP

  # Flush ParallelCluster chain, if required
  if [[ $flush == "true" ]]; then
    iptables --flush $PARALLELCLUSTER_CHAIN
    info "ParallelCluster chain flushed"
    exit 0
  fi

  # Delete rule: ACCEPT/REJECT user, for every user to unset
  IFS=","
  for user in $unset_users; do
    info "Deleting rules related to IMDS access for user: $user"
    iptables_delete $PARALLELCLUSTER_CHAIN $IMDS_IP "ACCEPT" $user
    iptables_delete $PARALLELCLUSTER_CHAIN $IMDS_IP "REJECT" $user
  done

  # Add rule: ACCEPT user, for every allowed user
  for user in $allow_users; do
    info "Allowing IMDS access for user: $user"
    iptables_add $PARALLELCLUSTER_CHAIN $IMDS_IP "ACCEPT" $user
  done

  # Add rule: REJECT user, for every denied user
  for user in $deny_users; do
    info "Denying IMDS access for user: $user"
    iptables_add $PARALLELCLUSTER_CHAIN $IMDS_IP "REJECT" $user
  done

  # Add rule: REJECT not allowed users
  info "Denying IMDS access for not allowed users"
  iptables_add $PARALLELCLUSTER_CHAIN $IMDS_IP "REJECT"
}

main "$@"
