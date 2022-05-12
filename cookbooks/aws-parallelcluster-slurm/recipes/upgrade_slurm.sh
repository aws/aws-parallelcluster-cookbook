#!/bin/bash
set -e

if /opt/slurm/bin/scontrol show partitions | grep -E "State=(UP|DOWN|DRAIN)"
then
  echo "There are partitions in UP, DOWN, DRAIN state. Please execute 'pcluster update-compute-fleet --cluster-name CLUSTER_NAME --status STOP_REQUESTED' to stop the cluster before upgrading Slurm."
  exit 1
fi

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

echo "Stopping ParallelCluster daemons"
systemctl stop supervisord

echo "Stopping Slurm controller"
systemctl stop slurmctld

echo "Backing up previous Slurm installation"
mv /opt/slurm /opt/slurm.bak

cd /etc/chef
cat > cookbooks/aws-parallelcluster/recipes/upgrade_slurm.rb << EOF
node.default['cluster']['slurm']['version'] = '21-08-8-2'
node.default['cluster']['slurm']['url'] = "https://github.com/SchedMD/slurm/archive/slurm-#{node['cluster']['slurm']['version']}.tar.gz"
node.default['cluster']['slurm']['sha1'] = 'f7687c11f024fbbe5399b93906d1179adc5c3fb6'
include_recipe 'aws-parallelcluster-slurm::install_slurm'

EOF
cinc-client -z -o aws-parallelcluster::upgrade_slurm

echo "Copy Slurm config to the new installation"
cp -Rp /opt/slurm.bak/etc /opt/slurm/etc

echo "Starting Slurm controller"
systemctl start slurmctld

echo "Starting ParallelCluster daemons"
systemctl start supervisord
