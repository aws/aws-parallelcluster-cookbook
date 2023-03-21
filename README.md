AWS ParallelCluster Cookbook
============================

[![codecov](https://codecov.io/gh/aws/aws-parallelcluster-cookbook/branch/develop/graph/badge.svg)](https://codecov.io/gh/aws/aws-parallelcluster-cookbook)
[![Build Status](https://github.com/aws/aws-parallelcluster-cookbook/actions/workflows/ci.yml/badge.svg?event=push)](https://github.com/aws/aws-parallelcluster-cookbook/actions)

This repo contains the AWS ParallelCluster Chef cookbook used in AWS ParallelCluster.

# Development

## About kitchen tests

Kitchen is used to automatically test cookbooks across any combination of platforms and test suites.
It requires  cinc-workstation to be installed on your environment:

curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-workstation -v 23


In order to test on docker containers, you also need docker installed on your environment.


### Helpers

`kitchen.docker.sh` and `kitchen.ec2.sh` help you run kitchen tests virtually without any further environment setup.

You must however do some initial setup on your AWS account in order to be able to use defaults from `kitchen.ec2.sh`.
Take a look at comments at the top of the script in order to understand how to use it.

Both scripts can be run as follows:

```
kitchen.*.sh <context> <kitchen parameters>
```

`<context>` is your test context, like `recipes-config` or `resources-install`.


For instance:

```
./kitchen.docker.sh recipes-install test cfnconfig-mixed -c 5 -l debug

./kitchen.ec2.sh resources-config test -c 5
```

To find all possible contexts you can run:
```bash
ls kitchen.{recipes,resources,validate}*.yml
```


Example of `.kitchen.env.sh` file you can define in your cookbook root folder:

```
export KITCHEN_KEY_NAME=your-key
export KITCHEN_AWS_REGION=eu-west-1
export KITCHEN_SUBNET_ID=subnet-xxx
export KITCHEN_SSH_KEY_PATH=/path/your-key.pem
export KITCHEN_SECURITY_GROUP_ID=sg-your-group

# amis for eu-west-1
export KITCHEN_ALINUX2_AMI=ami-xxxxxxxxxxxxxxxxx
export KITCHEN_REDHAT8_AMI=ami-xxxxxxxxxxxxxxxxx
export KITCHEN_CENTOS7_AMI=ami-xxxxxxxxxxxxxxxxx
export KITCHEN_UBUNTU18_AMI=ami-xxxxxxxxxxxxxxxxx
export KITCHEN_UBUNTU20_AMI=ami-xxxxxxxxxxxxxxxxx
```

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
  chef_version: 17 # Chef version aligned with the one used to build the images
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
