default['cluster']['region'] = 'us-east-1'

# AWS domain
default['cluster']['aws_domain'] = aws_domain

# URL for ParallelCluster Artifacts stored in public S3 buckets
# ['cluster']['region'] will need to be defined by image_dna.json during AMI build.
default['cluster']['base_build_url'] = "s3://aws-parallelcluster-dev-build-dependencies"
default['cluster']['artifacts_s3_url'] = "https://aws-parallelcluster-dev-commercial.s3.#{node['cluster']['aws_domain']}/archives"
default['cluster']['artifacts_build_url'] = "#{node['cluster']['base_build_url']}/archives/dependencies"
