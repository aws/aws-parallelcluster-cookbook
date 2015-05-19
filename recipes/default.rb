#
# Cookbook Name:: cfncluster
# Recipe:: default
#
# Copyright (c) 2014 The Authors, All Rights Reserved.
include_recipe 'cfncluster::sge_install'
include_recipe 'cfncluster::openlava_install'
include_recipe 'cfncluster::torque_install'
include_recipe 'cfncluster::slurm_install'
