#!/bin/bash

# This script sets up environment for building cfncluster ami
# Launch EC2 machine with amazon linux and run this script

# Get latest packages and Development tools
sudo yum -y update
sudo yum -y groupinstall 'Development Tools'

# Get chefdk
# Verify cookbook chef version in packer_variables.json file
wget https://packages.chef.io/files/stable/chefdk/3.0.36/el/7/chefdk-3.0.36-1.el7.x86_64.rpm
sudo rpm --install chefdk-3.0.36-1.el7.x86_64.rpm
chef -v

# Get Packer - tool used to build ami
wget https://releases.hashicorp.com/packer/1.2.4/packer_1.2.4_linux_amd64.zip
unzip packer_1.2.4_linux_amd64.zip
# Copy packer to PATH
sudo cp packer /usr/local/bin/
packer --version

# Get cfncluster cookbook - update to your own fork in case
# if you are testing your changes
# git clone https://github.com/awslabs/cfncluster-cookbook.git
# cd cfncluster-cookbook

# Run ami builder script
# ./build_ami.sh <operating_system> <region> <public/private>
# example
# ./build_ami.sh all us-east-1 private
