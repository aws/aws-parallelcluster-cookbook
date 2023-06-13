## System Tests

### Overview

The system tests is a mocked (virtual) environment that is provided for testing
portions of this repository (the AWS ParallelCluster Cookbooks) in a manner that
can be run either locally or in a testing environment.


### Components

There are two main phases for leveraging cookbooks:
- Installation -- which includes the recipes that AMI creation time.
- Configuration -- which includes the recipes that run during node bootup (runtime).

These two phases correspond to two phases within the system tests:
- container creation -- mimicks the "Installation" phase by running much of what the
cloudformation process does during AMI creation (e.g. installing CINC) as well as
actually running the `aws-parallelcluster::default` recipe.

### Installation / Docker Creation
The Dockerfile contains a few steps, mainly for the purposes of caching:

It starts by installing many packages that are installed during the
recipes as a way to cache this process to speed up repeated runs.

Next, the Dockerfile includes the installation of CINC from a known location so
that this process can be cached as well as it is less likely to change. Then,
an `image_dna.json` file and a `test_attributes.rb` file are copied into the
system.  These two files are used to customize the installation process in a
way that corresponds to an mocked environment that would be similar to that of
what would be present on a node during AMI creation.

Finally, the Dockerfile runs the `bootstrap.sh` process. This script is
responsible for mocking several applications which would be available on a node
but do not make sense in a virtual environment (e.g. `sysctl`, `modprobe`, etc...).
The `bootstrap.sh` process then launches the `cinc-client` with the `aws-parallelcluster::default` recipe 
as the cloudformation would.

### Configuration / Docker Run
Once the container is bulit that represents the base image, the installation recipes
can be run using this container. This is done by mounting the repository into the
container as well as a `dna.json` file and running the script called `systemd` that
will run the corresponding configuration recipes. This script is called `systemd`
so that chef will follow the path for a system that has `systemd` as its init system.

The `systemd` script additionally mocks some programs which are not setup to run
in the environment (e.g. `iptables`, `hostname` and `systemctl`) and then runs the
configuration recipes as would be done during node boot time.


### Full Testing
The `system_tests/test.sh` script runs the full process described above.

### Skipping tests
A few of the tests are not setup to run in Docker environment and thus can be
skipped by checking the `on_docker?` condition from within the recipe.


### Testing the installation
In order to test the installation phase, you can comment out the last line of the `bootstrap.sh` 
script, create the docker container as the `test.sh` script does, and then drop into the created
container with the following command:
```
docker run -ti chef-base:latest /bin/bash
```

Now simply run the command that was commented. This provides a convenient way
to iterate on the installation scripts.

```
cinc-client --local-mode --config /etc/chef/client.rb --log_level info --force-formatter --no-color --chef-zero-port 8889 --json-attributes /etc/parallelcluster/image_dna.json --override-runlist aws-parallelcluster::default
```

### Testing the configuration
Frequently it is desirable to test portions of the configuration process without
starting from the beginning. In this case, it is possible to run a virtualized environment
based on the built docker container. The following command will provide a bash shell
starting at the end of the installation phase:

```
docker run -ti \
    --rm=true \
    --name=chef_configure \
    -v $PWD:/build \
    -v $PWD/system_tests/dna.json:/etc/chef/dna.json \
    chef-base:latest \
    /bin/bash
```
