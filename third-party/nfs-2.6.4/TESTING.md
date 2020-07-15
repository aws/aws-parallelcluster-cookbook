# Cookbook TESTING doc

This document describes the process for testing Chef community cookbooks using ChefDK.

## Testing Prerequisites

A working ChefDK installation set as your system's default ruby. ChefDK can be downloaded at <https://downloads.chef.io/chef-dk/>

Hashicorp's [Vagrant](https://www.vagrantup.com/downloads.html) and Oracle's [Virtualbox](https://www.virtualbox.org/wiki/Downloads) for integration testing.

## Installing dependencies

Cookbooks may require additional testing dependencies that do not ship with ChefDK directly. These can be installed into the ChefDK ruby environment with the following commands

Install dependencies:

```shell
chef exec bundle install
```

Update any installed dependencies to the latest versions:

```shell
chef exec bundle update
```

## Linting Rake tasks

There is a Rakefile in the repo for various testing and validation tasks.

To see the defined Rake tasks:

```shell
chef exec rake -T
```

To run unit tests:

```shell
chef exec rake chefspec
```

To run cookstyle linting,
(W)arn and (E)rror level will fail the build:

```shell
chef exec rake cookstyle
```

## Integration Testing

Integration testing is performed by Test Kitchen. After a successful converge, tests are uploaded and ran out of band of Chef. Tests should be designed to ensure that a recipe has accomplished its goal.

## Integration Testing using Vagrant

Integration tests can be performed on a local workstation using VirtualBox as the virtualization hypervisor. To run tests against all available instances run:

```shell
chef exec kitchen test
```

To see a list of available test instances run:

```shell
chef exec kitchen list
```

To test specific instance run:

```shell
chef exec kitchen test INSTANCE_NAME
```
