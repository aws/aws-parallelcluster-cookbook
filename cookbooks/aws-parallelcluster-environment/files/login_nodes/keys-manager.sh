#!/bin/bash
set -e
#
# Manage the creation and usage of the keys in the login nodes
#
# --create                      Create the required keys in the specified folder
# --import                      Copy the keys from the specified folder to the ssh folder
# --folder_keys <folder_path>   Full path of the folder which contains the generated keys
# --help                        Print this help message

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

  Manage the creation and usage of the keys in the login nodes

  --create                      Create the required keys in the specified folder
  --import                      Copy the keys from the specified folder to the ssh folder
  --folder-path <folder_path>   Full path of the folder which contains the generated keys
  --help                        Print this help message
EOF
}

function create_keys() {
  info "Creating host keys"
  ssh-keygen -t ecdsa -f "$FOLDER_PATH/ssh_host_ecdsa_key" -q -P ""
  ssh-keygen -t ed25519 -f "$FOLDER_PATH/ssh_host_ed25519_key" -q -P ""
  ssh-keygen -t rsa -f "$FOLDER_PATH/ssh_host_rsa_key" -q -P ""
  if is_ubuntu; then
    ssh-keygen -t dsa -f "$FOLDER_PATH/ssh_host_dsa_key" -q -P ""
  fi
}

function import_keys() {
  info "Importing host keys"
  rm -f /etc/ssh/ssh_host_*
  cp "$FOLDER_PATH/ssh_host_ecdsa"* /etc/ssh/
  cp "$FOLDER_PATH/ssh_host_ed25519"* /etc/ssh/
  cp "$FOLDER_PATH/ssh_host_rsa"* /etc/ssh/
  if is_ubuntu; then
    cp "$FOLDER_PATH/ssh_host_dsa"* /etc/ssh/
    chown root:root /etc/ssh/ssh_host_*
    chmod 600 /etc/ssh/ssh_host_*_key
  else
    chown root:ssh_keys /etc/ssh/ssh_host_*
    chmod 640 /etc/ssh/ssh_host_*_key
  fi
  chmod 644 /etc/ssh/ssh_host_*_key.pub
}

function is_ubuntu() {
  if grep -q "Ubuntu" <<< "$OS"; then
    return 0
  fi
  return 1
}

main() {
  # Global values
  CREATE="false"
  IMPORT="false"
  FOLDER_PATH=""
  OS=$(grep '^NAME' /etc/os-release)

  # Parse options
  while [ $# -gt 0 ] ; do
      case "$1" in
          --create)         CREATE="true"; shift;;
          --import)         IMPORT="true"; shift;;
          --folder-path)    FOLDER_PATH="$2"; shift 2;;
          --help)           help; exit 0;;
          *)                help; error "Unrecognized option '$1'";;
      esac
  done

  [ -z "$FOLDER_PATH" ] && error "You must provide a valid path for the generated keys"

  if [ $CREATE == "true" ]; then
      create_keys
  fi

  if [ $IMPORT == "true" ]; then
      import_keys
  fi

  exit 0
}

main "$@"
