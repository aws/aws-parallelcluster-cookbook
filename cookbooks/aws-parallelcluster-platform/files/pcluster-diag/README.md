# pcluster-diag

Diagnostics tool for AWS ParallelCluster nodes.

It runs a context-aware set of checks against a running cluster and produces a structured
report as JSON plus console output.

The tool is invoked via the `pcluster-diag` command and runs as root from whatever cluster node.

## Updating the tool

You can update it without waiting for a ParallelCluster release by running the commands below as root.

```bash
# Overwrite the tool source with the version on GitHub (replace develop with another branch or tag).
curl -fL https://github.com/aws/aws-parallelcluster-cookbook/archive/refs/heads/develop.tar.gz \
  | tar -xz --strip-components=5 -C /opt/parallelcluster/sources/pcluster-diag \
    --wildcards '*/cookbooks/aws-parallelcluster-platform/files/pcluster-diag/*'
```
