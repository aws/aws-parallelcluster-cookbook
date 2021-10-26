#!/bin/bash

DUMMY_DIR="/tmp"
ORIGINAL_SHARED_DIR="/opt/parallelcluster/shared"
CLUSTER_CONFIGURATION_FILE="cluster-config.yaml"
LAUNCH_TEMPLATES_CONFIG_FILE="launch_templates_config.json"
INSTANCE_TYPES_DATA_FILE="instance-types-data.json"
BYOS_SUBSTACK_OUTPUTS_FILE="byos_substack_outputs.json"
ORIGINAL_CLUSTER_CONFIGURATION="${ORIGINAL_SHARED_DIR}/${CLUSTER_CONFIGURATION_FILE}"
DUMMY_LAUNCH_TEMPLATES_CONFIG="${DUMMY_DIR}/${LAUNCH_TEMPLATES_CONFIG_FILE}"
ORIGINAL_LAUNCH_TEMPLATES_CONFIG="${ORIGINAL_SHARED_DIR}/${LAUNCH_TEMPLATES_CONFIG_FILE}"
DUMMY_INSTANCE_TYPES_DATA="${DUMMY_DIR}/${INSTANCE_TYPES_DATA_FILE}"
ORIGINAL_INSTANCE_TYPES_DATA="${ORIGINAL_SHARED_DIR}/${INSTANCE_TYPES_DATA_FILE}"
DUMMY_BYOS_SUBSTACK_OUTPUTS="${DUMMY_DIR}/${BYOS_SUBSTACK_OUTPUTS_FILE}"
ORIGINAL_BYOS_SUBSTACK_OUTPUTS="${ORIGINAL_SHARED_DIR}/${BYOS_SUBSTACK_OUTPUTS_FILE}"

help() {
  echo "Utility to call BYOS event handler for development/debugging purposes"
    echo
    echo "Syntax: $0 [--help] [--debug] [--launch-templates-config <launch templates config> --instance-types-data <instance types data> --byos-stack-outputs <byos substack outputs>] --cluster-configuration <cluster configuration> --event-name <event name>"
    echo "options:"
    echo "--help                    Print this help."
    echo "--debug                   Exec in debug mode (with set -x)."
    echo "--event-name              The name of the event to trigger, possible values are:"
    echo "                            HeadInit, HeadConfigure, HeadFinalize, ComputeInit, ComputeConfigure, ComputeFinalize, HeadClusterUpdate, HeadComputeFleetStart or HeadComputeFleetStop."
    echo "--cluster-configuration   Required local path to cluster configuration file, in YAML format."
    echo "--launch-templates-config Local path to launch templates config file, in JSON format. When not set, if instance is not created by cluster creation, dummy launch templates config is created, otherwise the one retrieved from cluster will be used"
    echo "--instance-types-data     Local path to instance types data file, in JSON format. When not set, if instance is not created by cluster creation, dummy instance types data is created, otherwise the one retrieved from cluster will be used"
    echo "--byos-substack-outputs   Local path to byos substack outputs file, in JSON format. When not set, if instance is not created by cluster creation, dummy byos substack outputs is created, otherwise the one retrieved from cluster will be used"
    echo
}

fail() {
  echo "$1"
  exit 1
}

log() {
  echo "$1" | ts "[%Y-%m-%d %H:%M:%S,000] - [invoke-byos-event-handler] - INFO:"
}

if [ $# -eq 0 ]; then
  help
fi

# Command parser
while [ $# -gt 0 ]; do
  case "$1" in
    --help)
      help
      exit 0
    ;;
    --debug)
      set -x
    ;;
    --event-name)
      event_name+=("$2")
      shift
    ;;
    --event-name=*)
      event_name+=("${1#*=}")
    ;;
    --cluster-configuration)
      cluster_configuration+=("$2")
      shift
    ;;
    --cluster-configuration=*)
      cluster_configuration+=("${1#*=}")
    ;;
    --launch-templates-config)
      launch_templates_config+=("$2")
      shift
    ;;
    --launch-templates-config=*)
      launch_templates_config+=("${1#*=}")
    ;;
    --instance-types-data)
      instance_types_data+=("$2")
      shift
    ;;
    --instance-types-data=*)
      instance_types_data+=("${1#*=}")
    ;;
    --byos-substack-outputs)
      byos_substack_outputs+=("$2")
      shift
    ;;
    --byos-substack-outputs=*)
      byos_substack_outputs+=("${1#*=}")
    ;;
    *)
      fail "Unrecognized option ($1)"
    ;;
  esac
  shift
done

# Checks
if [[ "$EUID" -ne 0 ]]; then
  fail "Utility must be executed as root (or with sudo)"
fi

if [[ -z "${event_name}" ]]; then
  fail "You must choose one event name"
fi

if [[ ! "${event_name}" =~ ^(HeadInit|HeadConfigure|HeadFinalize|ComputeInit|ComputeConfigure|ComputeFinalize|HeadClusterUpdate|HeadComputeFleetStart|HeadComputeFleetStop)$ ]]; then
  fail "Event name ${event_name} not supported"
fi

build_minimal_dna_json() {
  # Build minimal dna.json
  if [[ "${event_name}" =~ ^Head ]]; then
    node_type="HeadNode"
  else
    node_type="Compute"
  fi

  cat << EOF > /etc/chef/dna.json
{
  "cluster": {
    "node_type": "${node_type}"
  }
}
EOF
}

build_dna_json() {
  cat << EOF > /tmp/extra.json
{
  "cluster": {
    "cluster_config_path": "$(readlink -f ${cluster_configuration})",
    "launch_templates_config_path": "$(readlink -f ${launch_templates_config})",
    "instance_types_data_path": "$(readlink -f ${instance_types_data})",
    "event_name": "${event_name}",
    "byos": {
      "byos_substack_outputs_path": "$(readlink -f ${byos_substack_outputs})"
    }
  }
}
EOF

  jq --argfile f1 /etc/chef/dna.json --argfile f2 /tmp/extra.json -n '$f1 + $f2 | .cluster = $f1.cluster + $f2.cluster' > /tmp/dna.json
  log "Generated dna.json:"
  log "$(cat /tmp/dna.json)"
}

call_chef_run() {
  chef_command=(chef-client --local-mode \
    --config /etc/chef/client.rb \
    --log_level info \
    --force-formatter \
    --no-color \
    --chef-zero-port 8889 \
    --json-attributes /tmp/dna.json \
    --override-runlist aws-parallelcluster::invoke_byos_event_handler)

  log "Calling event handler with command (${chef_command[*]})"
  "${chef_command[@]}"
}

create_dummy_launch_templates_config() {
  launch_templates_config="${DUMMY_LAUNCH_TEMPLATES_CONFIG}"
  log "Launch templates config not specified, creating dummy one under (${launch_templates_config})"
  cat << EOF > ${launch_templates_config}
{
  "Queues": {
    "queue1": {
      "ComputeResources": {
        "computeresource1": {
          "LaunchTemplate": {
            "Version": "1",
            "Id": "lt-075e7de0a9ae5e44a"
          }
        }
      }
    },
    "queue2": {
      "ComputeResources": {
        "computeresource1": {
          "LaunchTemplate": {
            "Version": "1",
            "Id": "lt-095e488f2e549a9e7"
          }
        }
      }
    }
  }
}
EOF
}

create_dummy_instance_types_data() {
  instance_types_data="${DUMMY_INSTANCE_TYPES_DATA}"
  log "Instance types data not specified, creating dummy one under (${instance_types_data})"
  cat << EOF > ${instance_types_data}
{
  "c5.9xlarge": {
    "InstanceType": "c5.9xlarge",
    "CurrentGeneration": true,
    "FreeTierEligible": false,
    "SupportedUsageClasses": [
      "spot",
      "ondemand"
    ],
    "SupportedRootDeviceTypes": [
      "ebs"
    ],
    "SupportedVirtualizationTypes": [
      "hvm"
    ],
    "BareMetal": false,
    "Hypervisor": "nitro",
    "ProcessorInfo": {
      "SupportedArchitectures": [
        "x86_64"
      ],
      "SustainedClockSpeedInGhz": 3.4
    },
    "VCpuInfo": {
      "DefaultVCpus": 36,
      "DefaultCores": 18,
      "DefaultThreadsPerCore": 2,
      "ValidCores": [
        2,
        4,
        6,
        8,
        10,
        12,
        14,
        16,
        18
      ],
      "ValidThreadsPerCore": [
        1,
        2
      ]
    },
    "MemoryInfo": {
      "SizeInMiB": 73728
    },
    "InstanceStorageSupported": false,
    "EbsInfo": {
      "EbsOptimizedSupport": "default",
      "EncryptionSupport": "supported",
      "EbsOptimizedInfo": {
        "BaselineBandwidthInMbps": 9500,
        "BaselineThroughputInMBps": 1187.5,
        "BaselineIops": 40000,
        "MaximumBandwidthInMbps": 9500,
        "MaximumThroughputInMBps": 1187.5,
        "MaximumIops": 40000
      },
      "NvmeSupport": "required"
    },
    "NetworkInfo": {
      "NetworkPerformance": "10 Gigabit",
      "MaximumNetworkInterfaces": 8,
      "MaximumNetworkCards": 1,
      "DefaultNetworkCardIndex": 0,
      "NetworkCards": [
        {
          "NetworkCardIndex": 0,
          "NetworkPerformance": "10 Gigabit",
          "MaximumNetworkInterfaces": 8
        }
      ],
      "Ipv4AddressesPerInterface": 30,
      "Ipv6AddressesPerInterface": 30,
      "Ipv6Supported": true,
      "EnaSupport": "required",
      "EfaSupported": false,
      "EncryptionInTransitSupported": false
    },
    "PlacementGroupInfo": {
      "SupportedStrategies": [
        "cluster",
        "partition",
        "spread"
      ]
    },
    "HibernationSupported": true,
    "BurstablePerformanceSupported": false,
    "DedicatedHostsSupported": true,
    "AutoRecoverySupported": true,
    "SupportedBootModes": [
      "legacy-bios",
      "uefi"
    ]
  }
}
EOF
}

create_dummy_byos_substack_outputs() {
  byos_substack_outputs="${DUMMY_BYOS_SUBSTACK_OUTPUTS}"
  log "Instance types data not specified, creating dummy one under (${byos_substack_outputs})"
  cat << EOF > ${byos_substack_outputs}
{
   "Outputs": {
     "Key1": "Value1",
     "Key2": "Value2"
   }
}

EOF
}

# Main
if [[ -f "/etc/chef/dna.json" ]]; then
  log "Instance created as part of cluster creation"

  if [[ -z "${cluster_configuration}" ]]; then
    fail "Cluster configuration is required. You may want to use --cluster-configuration ${ORIGINAL_CLUSTER_CONFIGURATION}"
  fi

  if [[ -z "${launch_templates_config}" ]]; then
    log "Launch templates config not specified, using (${ORIGINAL_LAUNCH_TEMPLATES_CONFIG})"
    launch_templates_config="${ORIGINAL_LAUNCH_TEMPLATES_CONFIG}"
  fi

  if [[ -z "${instance_types_data}" ]]; then
    log "Instance types data not specified, using (${ORIGINAL_INSTANCE_TYPES_DATA})"
    instance_types_data="${ORIGINAL_INSTANCE_TYPES_DATA}"
  fi

  if [[ -z "${byos_substack_outputs}" ]]; then
    log "Byos substack outputs not specified, will be generated under (${ORIGINAL_BYOS_SUBSTACK_OUTPUTS}) if there is a substack with outputs."
    byos_substack_outputs="${ORIGINAL_BYOS_SUBSTACK_OUTPUTS}"
  fi
else
  log "Instance not created as part of cluster creation"

  if [[ -z "${cluster_configuration}" ]]; then
    fail "Cluster configuration is required"
  fi

  if [[ -z "${launch_templates_config}" ]]; then
    create_dummy_launch_templates_config
  fi

  if [[ -z "${instance_types_data}" ]]; then
    create_dummy_instance_types_data
  fi

  if [[ -z "${byos_substack_outputs}" ]]; then
    create_dummy_byos_substack_outputs
  fi

  build_minimal_dna_json
fi

build_dna_json

call_chef_run
