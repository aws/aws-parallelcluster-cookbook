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
  local iptables_command=$1
  local chain=$2
  local destination=$3
  local jump=$4
  local user=$5

  # Build iptables delete command
  if [[ -z $user ]]; then
    rule_args="$chain --destination $destination -j $jump"
  else
    rule_args="$chain --destination $destination -j $jump -m owner --uid-owner $user"
  fi

  local iptables_delete_command="$iptables_command -D $rule_args"

  # Remove rules
  local should_remove=true
  while $should_remove; do
    eval $iptables_delete_command 1>/dev/null 2>/dev/null || should_remove=false
  done
}

function iptables_add() {
  local iptables_command=$1
  local chain=$2
  local destination=$3
  local jump=$4
  local user=$5

  # Remove duplicate rules
  iptables_delete $iptables_command $chain $destination $jump $user

  # Remove opposite rules
  if [[ $jump == "ACCEPT" ]]; then
    iptables_delete $iptables_command $destination "REJECT" $user
  elif [[ $jump == "REJECT" ]]; then
    iptables_delete $iptables_command $destination "ACCEPT" $user
  fi

  # Build iptables add command
  if [[ -z $user ]]; then
    rule_args="$chain --destination $destination -j $jump"
  else
    rule_args="$chain --destination $destination -j $jump -m owner --uid-owner $user"
  fi

  local iptables_add_command="$iptables_command -A $rule_args"

  # Add rule
  eval $iptables_add_command
  info "Rule in chain $chain: $destination $jump $user"
}

function setup_chain() {
  local iptables_command=$1
  local chain=$2
  local source_chain=$3
  local destination=$4

  $iptables_command --new $chain 2>/dev/null && info "ParallelCluster chain created: $chain" \
  || info "ParallelCluster chain exists: $chain"

  iptables_add $iptables_command $source_chain $destination $chain
}

main() {
  # Constants
  PARALLELCLUSTER_CHAIN="PARALLELCLUSTER_IMDS"
  OUTPUT_CHAIN="OUTPUT"
  IMDS_IP="169.254.169.254"
  IMDS_IP6="fd00:ec2::254"
  IPTABLE_CMD="iptables"
  IPTABLE_CMD_V6="ip6tables"

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

  IFS=","
  for ip_version_address in $IPTABLE_CMD,$IMDS_IP $IPTABLE_CMD_V6,$IMDS_IP6
  do
    set -- $ip_version_address
    iptables_command=$1
    ip=$2

    # Check required commands
    command -v $iptables_command >/dev/null || error "Cannot find required command: $iptables_command"

    # Check arguments and options
    if [[ -z $allow_users && -z $deny_users && -z $unset_users && -z $flush ]]; then
      error "Missing at least one mandatory option: '--allow', '--deny', '--unset', '--flush'"
    fi

    # Setup ParallelCluster chain
    setup_chain $iptables_command $PARALLELCLUSTER_CHAIN $OUTPUT_CHAIN $ip

    # Flush ParallelCluster chain, if required
    if [[ $flush == "true" ]]; then
      $iptables_command --flush $PARALLELCLUSTER_CHAIN
      info "ParallelCluster chain flushed"
      exit 0
    fi

    # Delete rule: ACCEPT/REJECT user, for every user to unset
    for user in $unset_users; do
      info "Deleting rules related to IMDS access for user: $user"
      iptables_delete $iptables_command $PARALLELCLUSTER_CHAIN $ip "ACCEPT" $user
      iptables_delete $iptables_command $PARALLELCLUSTER_CHAIN $ip "REJECT" $user
    done

    # Add rule: ACCEPT user, for every allowed user
    for user in $allow_users; do
      info "Allowing IMDS access for user: $user"
      iptables_add $iptables_command $PARALLELCLUSTER_CHAIN $ip "ACCEPT" $user
    done

    # Add rule: REJECT user, for every denied user
    for user in $deny_users; do
      info "Denying IMDS access for user: $user"
      iptables_add $iptables_command $PARALLELCLUSTER_CHAIN $ip "REJECT" $user
    done

    # Add rule: REJECT not allowed users
    info "Denying IMDS access for not allowed users"
    iptables_add $iptables_command $PARALLELCLUSTER_CHAIN $ip "REJECT"
  done
}

main "$@"
