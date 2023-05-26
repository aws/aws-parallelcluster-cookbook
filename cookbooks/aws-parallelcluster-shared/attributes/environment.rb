default['cluster']['region'] = 'us-east-1'

# AWS domain
default['cluster']['aws_domain'] = aws_domain

# URL for ParallelCluster Artifacts stored in public S3 buckets
# ['cluster']['region'] will need to be defined by image_dna.json during AMI build.
default['cluster']['artifacts_s3_url'] = "https://#{node['cluster']['region']}-aws-parallelcluster.s3.#{node['cluster']['region']}.#{node['cluster']['aws_domain']}/archives"

# Adding temporarily while working on nvidia setup
# TODO: move to platform cookbook
default['cluster']['nvidia']['enabled'] = 'no'
default['cluster']['nvidia']['driver_version'] = '470.182.03'
