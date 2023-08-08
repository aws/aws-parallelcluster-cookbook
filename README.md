AWS ParallelCluster Cookbook
============================

[![codecov](https://codecov.io/gh/aws/aws-parallelcluster-cookbook/branch/develop/graph/badge.svg)](https://codecov.io/gh/aws/aws-parallelcluster-cookbook)
[![Build Status](https://github.com/aws/aws-parallelcluster-cookbook/actions/workflows/ci.yml/badge.svg?event=push)](https://github.com/aws/aws-parallelcluster-cookbook/actions)

This repo contains the AWS ParallelCluster Chef cookbook used in AWS ParallelCluster.

# Code structure

The root folder of the cookbook repository can be considered the main cookbook, since it contains two files: `Berksfile` and `metadata.rb`.
These files are used by the CLI (build image time) and `user-data.sh` code to [vendor](https://docs.chef.io/workstation/berkshelf/#berks-vendor)
the other sub-cookbooks and third party cookbooks.

The main cookbook does not contain any recipe, attribute or library. They are distributed in the functional cookbooks under the `cookbooks` folder
defined as follows:
- `aws-parallelcluster-entrypoints` is the cookbook to define the external interface, contains recipes called by AMI builder, cluster setup, cluster update, etc. 
  The recipes in this cookbook are called directly by the CLI or CI/CD. It orchestrates invocation of recipes/resources from other cookbooks;
- `aws-parallelcluster-platform` OS packages and system configuration (directories, users, services, drivers);
- `aws-parallelcluster-environment` AWS services configuration and usage, such as shared file systems, directory service and network interfaces;
- `aws-parallelcluster-computefleet` slurm specific scaling logic, compute fleet scripts and daemons;
- `aws-parallelcluster-awsbatch` files required to support AWS Batch as scheduler;
- `aws-parallelcluster-slurm` files required to support Slurm as a scheduler and its dependencies (Munge, MySQL for accounting, etc), it depends by `aws-parallelcluster-computefleet`;

Finally, some common code, such as source/script directories, usernames, package installer etc., are located in a cookbook 
which every other cookbook depend on, that is `aws-parallelcluster-shared`.
Each cookbook hosts recipes and resources, attributes, functions, files and templates belonging to its functional area.

Every cookbook contains ChefSpec and Kitchen tests for its code.
However, the code in a cookbook might require that some other code from a different cookbook not listed among dependencies,
to be executed as a prerequisite (test setup phase). For this reason `aws-parallelcluster-tests` cookbook must depend on every other cookbook.

The `test` folder contains Python unit tests files and Kitchen [environment](https://docs.chef.io/environments/) files.

The `kitchen` folder contains utility files used when running Inspec tests locally.

The `cookbooks/third-party` folder contains cookbooks from marketplace. They must be regularly updated and should not be modified by hand.
They have been pre-downloaded and stored in our repository to avoid contacting Chef Marketplace at AMI build time and cluster creation.
You can find more information about them in the `cookbooks/third-party/THIRD-PARTY-LICENSES.txt` file.

# Development

## About ChefSpec Tests

[ChefSpec](https://github.com/chefspec/chefspec) is a unit testing framework for testing Chef cookbooks. 
It is very fast, and we use it to verify recipes with multiple branches (e.g. HeadNode vs ComputeNode) work as expected.
They don't need virtual machines or cloud servers. They can be executed locally by executing:

```
cd cookbooks/aws-parallelcluster-platform
# run all the ChefSpec tests in a cookbook
chef exec rspec
# run a specific ChefSpec test
chef exec rspec ./spec/unit/recipes/sudo_config_spec.rb 
```

They are automatically executed as GitHub actions, see definition in `.github/ci.yml`.

## About Kitchen Tests

Kitchen is used to automatically test cookbooks across any combination of platforms and test suites.
It requires cinc-workstation to be installed on your environment:

`brew install --cask cinc-workstation` on MacOS

or

`curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-workstation -v 23`

Make sure you have set a locale in your local shell environment, by exporting the `LC_ALL` and `LANG` variables, 
for example by adding to your `.bashrc` or `.zshrc` the following and sourcing the file:

```
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
```

To speed up the transfer of files when kitchens are run on ec2 instances,
the [transport](https://docs.chef.io/workstation/config_yml_kitchen/#transport-settings) selected is [kitchen-transport-speedy](https://github.com/criteo/kitchen-transport-speedy).
To install `kitchen-transport-speedy` in the kitchen embedded ruby environment please run: `/opt/cinc-workstation/embedded/bin/gem install kitchen-transport-speedy`.

In order to test on docker containers, you also need `docker` installed on your environment.
Please note that not all the tests can run on docker so in any case we need to validate our recipes on EC2.
You can use `on_docker?` condition to skip execution of some recipes steps, resource actions or controls execution on docker.
Please look at "Known issues with docker" section of the README for specific issues (e.g. when running kitchen tests on non `amd64` architectures).

### Kitchen tests helpers

`kitchen.docker.sh` and `kitchen.ec2.sh` help you run kitchen tests virtually without any further environment setup.
They are wrappers of the `kitchen` command, so you can pass them all the options exposed by it. See `kitchen --help` for more details. 

You must do some initial setup on your AWS account in order to be able to use defaults from `kitchen.ec2.sh`. 
Default values are the following. Take a look at comments at the top of the script in order to understand how to use it.

```
: "${KITCHEN_AWS_REGION:=${AWS_DEFAULT_REGION:-eu-west-1}}"
: "${KITCHEN_KEY_NAME:=kitchen}"
: "${KITCHEN_SSH_KEY_PATH:="~/.ssh/${KITCHEN_KEY_NAME}-${KITCHEN_AWS_REGION}.pem"}"
: "${KITCHEN_AVAILABILITY_ZONE:=a}"
: "${KITCHEN_ARCHITECTURE:=x86_64}"
```

Both scripts can be run as follows:

```
kitchen.<ec2|docker>.sh <context> <kitchen parameters>
```

`<context>` is your test context, like `environment-config` or `platform-install`.
For example `./kitchen.docker.sh platform-install test nvidia` will execute `kitchen test` command, executing all the
tests for which the name starts with `nvidia` prefix, in `cookbooks/aws-parallelcluster-platform` directory on docker.

It is important to keep in mind that the parameter after the kitchen action is a pattern,
so it's important to choose the appropriate naming for kitchen tests suites.
For instance, we can use `nvidia-<context>` for nvidia-related tests, so that they can be run separately or together.
However, we should not have `nvidia` and `nvidia-something` tests, as we wouldn't be able to run only the first one on all OSes.

Examples of submission are:
```
# Run supervisord kitchen test from file kitchen.platform-install.yml in cookbooks/aws-parallelcluster-platform directory,
# for all OSes (concurrency 5) and log level debug
# Note that in this case "supervisord" is a pattern, so all the tests starting with "supervisord" string in that yaml file will be executed.
./kitchen.docker.sh platform-install test supervisord -c 5 -l debug

# Run converge phase only of kitchen from file kitchen.environment-config.yml in cookbooks/aws-parallelcluster-environment directory, for alinux2 only.
# This is useful when you want to test recipe execution only.
# Once you have executed the converge step, you can for example execute multiple times the verify step, to validate the tests you are writing.
./kitchen.ec2.sh environment-config converge efa-alinux2

# Run verify phase only from file kitchen.platform-config.yml in cookbooks/aws-parallelcluster-platform directory,
# useful if you're modifing the test logic without touching the recipes code.
./kitchen.ec2.sh platform-config verify sudo -c 5

# Login to the instance created with the converge step
./kitchen.ec2.sh platform-config login sudo-alinux2
```

A context must have the format `$subject-$phase`. 

Supported phases are:
- `install` (on EC2 it defaults to a bare base AMI)
- `config` (on EC2 it defaults to a ParallelCluster official AMI)

It will use `kitchen.${context}.yml` in the specific cookbook, i.e. in `cookbooks/aws-parallelcluster-$subject` dir.

You can override default values by setting environment variables in a `.kitchen.env.sh` file to be created in the cookbook root folder.
Example of `.kitchen.env.sh` file:

```
export KITCHEN_KEY_NAME=your-key  # ED25519 key type (required for Ubuntu 22)
export KITCHEN_SSH_KEY_PATH=/path/your-key.pem
export KITCHEN_AWS_REGION=eu-west-1
export KITCHEN_SUBNET_ID=subnet-xxx
export KITCHEN_SECURITY_GROUP_ID=sg-your-group
export KITCHEN_INSTANCE_TYPE=t2.large
export KITCHEN_IAM_PROFILE=test-kitchen  # required for tests with lifecycle hooks
```

### Kitchen tests definition

The different `kitchen.${context}.yml` files in the functional cookbooks contain a list of Inspec tests
for the different recipes and resources. 

Every test specifies:
- the `run_list` that is the list of recipes to be executed as preparatory steps as part of the `kitchen converge` phase:
  - the `recipe[aws-parallelcluster-tests::setup]` is a utility recipe that should be added to every test to prepare the environment
    and automatically execute resources and recipes listed as dependencies in the `dependencies` attributes.
  - the `recipe[aws-parallelcluster-tests::test_resource]` is a utility recipe to simplify testing of the custom resource defined in the
    `resource` attribute. Please check `test_resource` content to see which parameters you can pass to it.
- the `verifier` with the list of controls to execute as part of the `kitchen verify` phase, it's possible to use regex here,
  it can accept regular expressions in format `/regex/`.
- the node `attributes` that will be propagated in the test environment.
  - `resource` is a reserved attribute, used by `test_resource` recipe mentioned before.
  - `dependencies` is a reserved attribute, used by `setup` recipe mentioned before.
  - `cluster` structure permits to pass specific parameters to the test to simulate environment condition
    (i.e. dna.json configuration that should come from the CLI when executing the recipes in a real cluster)

Example of test definition:
```
- name: system_authentication
  run_list:
    - recipe[aws-parallelcluster-tests::setup]
    - recipe[aws-parallelcluster-tests::test_resource]
  verifier:
    controls:
      - /tag:config_system_authentication/
  attributes:
    resource: system_authentication:configure
    dependencies:
      - resource:system_authentication:setup
    cluster:
      directory_service:
        enabled: "true"
      node_type: HeadNode
```

When you execute a test like this with `kitchen test` command it will execute the recipes or resources actions specified in the `run_list`,
including `dependencies`, will set `cluster` attributes in the environment and at the end will execute the `verify` steps by executing
the listed `controls`. 
The `kitchen test` command will execute all the steps and will destroy the instance at the end. If you want to preserve the instance
you can execute the step one by one, check `kitchen help` for more details.


### Kitchen tests as GitHub actions and as part of CI/CD 

As you can see in the `.github/workflows/dokken-system-tests.yml` we are executing both install and config recipes as GitHub actions. 
We execute install steps in the `Kitchen Test Install` (to simulate AMI build) and then re-using the container to validate the config steps, 
in the `Kitchen Test Config`.

In our daily CI/CD we build an AMI (calling the `aws-parallelcluster-entrypoints::install` recipe) and then execute kitchen tests on top of it.

Both CI/CD and GitHub actions use the `kitchen.validate-config.yml` file in the root folder to validate the config steps.
If you look at it, you can see it runs all the `inspec_tests` from all the cookbooks by executing the 
controls matching the `/tag:config/` regex.
```
verifier:
  inspec_tests:
    - /tmp/cookbooks/aws-parallelcluster-awsbatch/test
    - /tmp/cookbooks/aws-parallelcluster-platform/test
    - /tmp/cookbooks/aws-parallelcluster-environment/test
    - /tmp/cookbooks/aws-parallelcluster-computefleet/test
    ...
  controls:
    - /tag:config/
```

This means that if you want a specific control to be executed as part of the CI/CD or GitHub action you should
use `tag:config_` as prefix in the control name.

Note that not all the Inspec tests can run on GitHub and on the CI/CD because, as you can see in the `kitchen.validate-config.yml`,
in this case the `run_list` is defined as follows:
```
_run_list: &_run_list
  - recipe[aws-parallelcluster-tests::setup]
  - recipe[aws-parallelcluster-entrypoints::init]
  - recipe[aws-parallelcluster-entrypoints::config]
  - recipe[aws-parallelcluster-entrypoints::finalize]
  - recipe[aws-parallelcluster-tests::tear_down]
```
without any attribute specified, so this could not match with the `run_list` or the `attributes` specified in the test definition.
So before adding the `tag:config_` prefix to a control name, please be sure that it can run even without specific setup.

If you want to execute some kitchen tests at the end of the build-image process, to validate that a created AMI
contains what we expect, you can use the `tag:install_` as prefix in the control name. They will be automatically executed by 
Image builder at the end of the build-image process (search for `tag:install_` in the CLI code to understand the details behind this mechanism).
Please note that if this test fails the build of the image will fail as well.

If you want to execute some kitchen tests as part of validate phase the build-image process without causing the build image to fail
you can use the `tag:testami_` as prefix. These tests will be executed when the image has already been created
(search for `tag:testami_` in the CLI code to understand the details behind this mechanism).

Please note that a test suite name can contain multiple tags (for instance, `tag:install_tag:config_`), the code search for them
with a regex so it's not required to have them as prefix.

### Save and reuse Docker image

When you set the environment variable `KITCHEN_SAVE_IMAGE=true`, a successful `kitchen verify` phase will lead to 
the Docker image being committed with the tag `pcluster-${PHASE}/${INSTANCE_NAME}`.

For instance, if you successfully run
```
./kitchen.docker.sh platform-install test directories-alinux2
```
an image with tag `pcluster-install/directories-alinux2:latest` will be saved.

To use it in a later Kitchen test, `export KITCHEN_${PLATFORM}_IMAGE=<your_image>`.

For instance, to reuse the image from the example above, set `KITCHEN_ALINUX2_IMAGE=pcluster-install/directories-alinux2`.

We are using this approach to re-use the docker image created by the `Kitchen Test Install` in the following `Kitchen Test Config` phase
as part of the GitHub actions.


### Save and reuse EC2 image

The procedure described above also applies to EC2, with minor differences.

1. To keep the EC2 instance running while the image is being cooked, refrain from using `kitchen test` 
   or `kitchen destroy` commands. Opt for `kitchen verify` and destroy the instance once the AMI is ready.
2. Set `KITCHEN_${PLATFORM}_AMI=<ami_id>` to reuse the AMI.
   For instance, `KITCHEN_ALINUX2_AMI=ami-nnnnnnnnnnnnn`.

This is useful when you need a long list of dependencies to be installed in the AMI (e.g. Slurm recipes) to verify configuration steps. 

### Kitchen lifecycle hooks

Kitchen [lifecycle hooks](https://kitchen.ci/docs/reference/lifecycle-hooks/) allow running commands 
before and/or after any phase of Kitchen tests (create, converge, verify, or destroy).

We leverage this feature in Kitchen tests to create/destroy AWS resources (see `kitchen.global.yaml` file. 

For each phase, a generic run script executes custom 
`${THIS_DIR}/${KITCHEN_COOKBOOK_PATH}/test/hooks/${KITCHEN_PHASE}/${KITCHEN_SUITE_NAME}/${KITCHEN_HOOK}.sh` script, if it exists.

__Example.__ 

`network_interfaces` Kitchen test suite in the `aws-parallelcluster-environment` cookbook requires a network interface to be attached to the node. 
- `cookbooks/aws-parallelcluster-environment/test/hooks/config/network_interfaces/post_create.sh`: creates ENI and attaches it to the instance
- `cookbooks/aws-parallelcluster-environment/test/hooks/config/network_interfaces/pre_destroy.sh`: detaches and deletes ENI.

### Use variables from lifecycle hooks as resource properties

In the `kitchen.global.yaml` we're configuring an [environment](https://docs.chef.io/environments/).

In the environment file (i.e. `test/environments/kitchen.rb`), for every value to pass and for every OS, 
you have to define a line like: `'<suite_name>-<variable_name>/<platform>' => 'placeholder'`. For instance:
```
default_attributes 'kitchen_hooks' => {
  'ebs_mount-vol_array/alinux2' => 'placeholder',
  ...
}
```

These environment variables will be available to the kitchen tests as node attributes:
`node['kitchen_hooks']['ebs_mount-vol_array/alinux2']`. 

To permit to use these environment variables as parameters attributes you have to use th `FROM-HOOK`
keyword in the test suite definition.
e.g. `resource: 'manage_ebs:mount {"shared_dir_array" : ["shared_dir"], "vol_array" : "FROM_HOOK-<suite_name>-<variable_name>"}'`

This value will be automatically replaced, searching for the `<suite_name>-<variable_name>/<platform>` in the environment.
You can find all the details of this mechanism in the `test_resource.rb`.

Note: the value of the property to be replaced must be a string even if it's an array.
It's up to the post_create script to define an array in the environment.

### Known issues with docker

#### Running kitchen tests on non `amd64` architectures

Running locally kitchen tests on system with CPU architecture other than `amd64` (i.e. Apple Silicon that have `arm64`)
may run in a known **dokken** issue (tracked as https://github.com/test-kitchen/kitchen-dokken/issues/288).

All tests will fail with messages containing errors such as:

```
[qemu-x86_64: Could not open '/lib64/ld-linux-x86-64.so.2](https://stackoverflow.com/questions/71040681/qemu-x86-64-could-not-open-lib64-ld-linux-x86-64-so-2-no-such-file-or-direc)
```

To work around the issue, please ensure that the `cinc-workstation` version is `>= 23`, as it's the first one that has a
dokken version that features platform support.

Providing the correct platform configuration in `./kitchen.docker.yml` :

```
---
driver:
  name: dokken
  platform: linux/amd64
  pull_platform_image: false # Use the local images, prevent pull of docker images from Docker Hub,
  chef_version: 18 # Chef version aligned with the one used to build the images
  chef_image: cincproject/cinc
...
```

is required but not enough if images for different CPU architectures already are present in the local docker cache.
Local images of different architectures should be removed in order to work around the issue, then in subsequent
executions dokken will pull the ones for the specified platform and use those, since there are no other than those for
the correct architecture available locally.

Here are some examples to clean up local docker containers and images:

```
# removes running containers that may have been left dangling by previous
# executions of <your test prefix> test
docker rm \
  $(docker container stop \
    $(docker container ls -q --filter name='<your test prefix>*'))

# remove images from offending <your test prefix>
# you may want also to remove all dokken images
# (and safely remove all images, since subsequent executions will pull the
# required ones)
docker rmi \
  $(docker images --format '{{.Repository}}:{{.Tag}}' \
  | grep '<your test prefix>')
```

#### kitchen tests fail in `docker_config_creds` with NPE

**dokken** expects that `~/.docker/config.json` contains an `"auths"` key, fails in `docker_config_creds` with NPE
otherwise, this issue is tracked in upstream as: https://github.com/test-kitchen/kitchen-dokken/issues/290

### Known issues with EC2

#### Ubuntu22

On Ubuntu22, `kitchen create` keeps trying to connect to the instance via ssh indefinitely.
If you interrupt it and try to run `kitchen verify`, you see authentication failures. 

This happens because Ubuntu22 does not accept authentication via RSA key. You need to re-create a key pair 
using `ED25519` key type.

### Known issues with Berks

#### Kitchen doesn't see your changes

If Kitchen doesn't detect your changes, try
```
berks shelf uninstall ${COOKBOOK_NAME}
```

## About python tests

Python tests are configured in `tox.ini` file, including paths to python files.
If you move python files around, you need to fix python path accordingly.
