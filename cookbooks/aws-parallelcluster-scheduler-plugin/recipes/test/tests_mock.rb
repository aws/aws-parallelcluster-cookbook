# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-scheduler-plugin
# Recipe:: tests_mock
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Recipe used to mock node environment before the execution of kitchen tests

if node['cluster']['scheduler'] == 'plugin'
  case node['cluster']['node_type']
  when 'ComputeFleet'
    # mock files in shared location to be local to node
    node.override['cluster']['cluster_config_path'] = "/tmp/cluster-config.yaml"
    node.override['cluster']['launch_templates_config_path'] = "/tmp/launch-templates-config.json"
    node.override['cluster']['instance_types_data_path'] = "/tmp/instance-types-data.json"

    # mock cluster config content
    file node['cluster']['cluster_config_path'] do
      content <<-CLUSTER_CONFIG
Image:
  Os: fake-os
HeadNode:
  InstanceType: c5.xlarge
  Networking:
    SubnetId: subnet-12345678
  Ssh:
    KeyName: any-key-name
Scheduling:
  Scheduler: plugin
  SchedulerSettings:
    GrantSudoPrivileges: false
    SchedulerDefinition:
      PluginInterfaceVersion: "1.0"
      Events:
        HeadInit:
          ExecuteCommand:
            Command: env && echo "HeadInit executed"
        HeadConfigure:
          ExecuteCommand:
            Command: env && echo "HeadConfigure executed"
        HeadFinalize:
          ExecuteCommand:
            Command: env && echo "HeadFinalize executed"
        ComputeInit:
          ExecuteCommand:
            Command: env && echo "ComputeInit executed"
        ComputeConfigure:
          ExecuteCommand:
            Command: env && echo "ComputeConfigure executed"
        ComputeFinalize:
          ExecuteCommand:
            Command: env && echo "ComputeFinalize executed"
        HeadClusterUpdate:
          ExecuteCommand:
            Command: env && echo "HeadClusterUpdate executed"
        HeadComputeFleetUpdate:
          ExecuteCommand:
            Command: |
              env && echo "HeadComputeFleetUpdate executed"
      Monitoring:
        Logs:
          Files:
            - FilePath: /var/log/cfn-init-cmd.log
              TimestampFormat: "%Y-%m-%d %H:%M:%S,%f"
              NodeType: HEAD
              LogStreamName: test_cfn_init_cmd.log
      Tags:
        - Key: SchedulerPluginTag
          Value: SchedulerPluginTagValue
  SchedulerQueues:
    - Name: queue1
      Networking:
        SubnetIds:
          - subnet-12345678
      ComputeResources:
        - Name: compute-resource-1
          InstanceType: c5.xlarge
          MinCount: 0
          MaxCount: 10
          DisableSimultaneousMultithreading: false
          Efa:
            Enabled: false
            GdrSupport: false
        - Name: compute-resource-2
          InstanceType: c4.xlarge
          MinCount: 0
          MaxCount: 10
          DisableSimultaneousMultithreading: false
          Efa:
            Enabled: false
            GdrSupport: false
      CLUSTER_CONFIG
      mode '0644'
      owner 'root'
      group 'root'
    end

    # mock instance type data content
    file node['cluster']['instance_types_data_path'] do
      content <<-INSTANCE_TYPE_DATA
{
  "c5.xlarge": {
    "InstanceType": "c5.xlarge",
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
      "DefaultVCpus": 4,
      "DefaultCores": 2,
      "DefaultThreadsPerCore": 2,
      "ValidCores": [
        2
      ],
      "ValidThreadsPerCore": [
        1,
        2
      ]
    },
    "MemoryInfo": {
      "SizeInMiB": 8192
    },
    "InstanceStorageSupported": false,
    "EbsInfo": {
      "EbsOptimizedSupport": "default",
      "EncryptionSupport": "supported",
      "EbsOptimizedInfo": {
        "BaselineBandwidthInMbps": 1150,
        "BaselineThroughputInMBps": 143.75,
        "BaselineIops": 6000,
        "MaximumBandwidthInMbps": 4750,
        "MaximumThroughputInMBps": 593.75,
        "MaximumIops": 20000
      },
      "NvmeSupport": "unsupported"
    },
    "NetworkInfo": {
      "NetworkPerformance": "Up to 10 Gigabit",
      "MaximumNetworkInterfaces": 4,
      "MaximumNetworkCards": 1,
      "DefaultNetworkCardIndex": 0,
      "NetworkCards": [
        {
          "NetworkCardIndex": 0,
          "NetworkPerformance": "Up to 10 Gigabit",
          "MaximumNetworkInterfaces": 4
        }
      ],
      "Ipv4AddressesPerInterface": 15,
      "Ipv6AddressesPerInterface": 15,
      "Ipv6Supported": true,
      "EnaSupport": "required",
      "EfaSupported": false
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
      "uefi",
      "legacy-bios"
    ]
  },
  "c4.xlarge": {
    "InstanceType": "c4.xlarge",
    "CurrentGeneration": true,
    "FreeTierEligible": false,
    "SupportedUsageClasses": [
      "on-demand",
      "spot"
    ],
    "SupportedRootDeviceTypes": [
      "ebs"
    ],
    "SupportedVirtualizationTypes": [
      "hvm"
    ],
    "BareMetal": false,
    "Hypervisor": "xen",
    "ProcessorInfo": {
      "SupportedArchitectures": [
        "x86_64"
      ],
      "SustainedClockSpeedInGhz": 2.9
    },
    "VCpuInfo": {
      "DefaultVCpus": 4,
      "DefaultCores": 2,
      "DefaultThreadsPerCore": 2,
      "ValidCores": [
        1,
        2
      ],
      "ValidThreadsPerCore": [
        1,
        2
      ]
    },
    "MemoryInfo": {
      "SizeInMiB": 7680
    },
    "InstanceStorageSupported": false,
    "EbsInfo": {
      "EbsOptimizedSupport": "default",
      "EncryptionSupport": "supported",
      "EbsOptimizedInfo": {
        "BaselineBandwidthInMbps": 750,
        "BaselineThroughputInMBps": 93.75,
        "BaselineIops": 6000,
        "MaximumBandwidthInMbps": 750,
        "MaximumThroughputInMBps": 93.75,
        "MaximumIops": 6000
      },
      "NvmeSupport": "unsupported"
    },
    "NetworkInfo": {
      "NetworkPerformance": "High",
      "MaximumNetworkInterfaces": 4,
      "MaximumNetworkCards": 1,
      "DefaultNetworkCardIndex": 0,
      "NetworkCards": [
        {
          "NetworkCardIndex": 0,
          "NetworkPerformance": "High",
          "MaximumNetworkInterfaces": 4
        }
      ],
      "Ipv4AddressesPerInterface": 15,
      "Ipv6AddressesPerInterface": 15,
      "Ipv6Supported": true,
      "EnaSupport": "unsupported",
      "EfaSupported": false
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
    "AutoRecoverySupported": true
  }
}
      INSTANCE_TYPE_DATA
      mode '0644'
      owner 'root'
      group 'root'
    end
  end

  # mock cluster stack arn
  node.override['cluster']['stack_arn'] = "arn:aws:cloudformation:eu-west-1:1234567890:stack/fake-stack/07684870-8b1d-11ec-b57f-0a6d1e873bc9"

  # mock launch templates config content
  file node['cluster']['launch_templates_config_path'] do
    content <<-LAUNCH_TEMPLATE_CONFIG
{
  "Queues": {
    "queue1": {
      "ComputeResources": {
        "computeresource1": {
          "LaunchTemplate": {
            "Version": "1",
            "Id": "lt-1234567890abcd"
          }
        }
      }
    },
    "queue2": {
      "ComputeResources": {
        "computeresource1": {
          "LaunchTemplate": {
            "Version": "1",
            "Id": "lt-dcba0987654321"
          }
        }
      }
    }
  }
}
    LAUNCH_TEMPLATE_CONFIG
    mode '0644'
    owner 'root'
    group 'root'
  end
end
