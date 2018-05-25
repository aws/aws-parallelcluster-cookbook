#!/bin/bash

# This script sets up environment for building cfncluster ami
# Launch Ec2 machine with amazon linux and run this script

# Get latest packages and Development tools
sudo yum -y update
sudo yum -y groupinstall 'Development Tools'

# Get chefdk - As of now we use 1.4.3
# Verify cookbook chef version in metadata.rb file
# In case you see version mismatch, Please install
# chefdk version referred in metadata file
wget https://packages.chef.io/files/stable/chefdk/1.4.3/el/7/chefdk-1.4.3-1.el7.x86_64.rpm
sudo rpm --install chefdk-1.4.3-1.el7.x86_64.rpm
chef -v

# Get Packer - tool used to build ami
# As of now we use 1.1.1
wget https://releases.hashicorp.com/packer/1.1.1/packer_1.1.1_linux_amd64.zip
unzip packer_1.1.1_linux_amd64.zip
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
