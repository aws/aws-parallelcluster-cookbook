#!/bin/bash
echo "*** Fix relative paths in dependent cookbooks"
rm -rf /tmp/cookbooks
mkdir -p /tmp/cookbooks/aws-parallelcluster-awsbatch
mkdir -p /tmp/cookbooks/aws-parallelcluster-common/test
mkdir -p /tmp/cookbooks/aws-parallelcluster-platform
mkdir -p /tmp/cookbooks/aws-parallelcluster-environment
mkdir -p /tmp/cookbooks/aws-parallelcluster-computefleet
mkdir -p /tmp/cookbooks/aws-parallelcluster-shared
cp -r cookbooks/aws-parallelcluster-awsbatch/test /tmp/cookbooks/aws-parallelcluster-awsbatch
cp -r cookbooks/aws-parallelcluster-common/test/common /tmp/cookbooks/aws-parallelcluster-common/test
cp -r cookbooks/aws-parallelcluster-platform/test /tmp/cookbooks/aws-parallelcluster-platform
cp -r cookbooks/aws-parallelcluster-environment/test /tmp/cookbooks/aws-parallelcluster-environment
cp -r cookbooks/aws-parallelcluster-computefleet/test /tmp/cookbooks/aws-parallelcluster-computefleet
cp -r cookbooks/aws-parallelcluster-shared/test /tmp/cookbooks/aws-parallelcluster-shared
sed -i.bak "s#path: ../aws-parallelcluster#path: /tmp/cookbooks/aws-parallelcluster#g" /tmp/cookbooks/aws-parallelcluster-*/test/inspec.yml
