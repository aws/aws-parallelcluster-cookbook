# Developing pcluster-diag

This document is for ParallelCluster engineers working on the `pcluster-diag` tool itself.

## Development environment

```bash
# Create the virtual environment
pyenv virtualenv 3.10 pcluster-diag

# Activate the virtual environment
pyenv activate pcluster-diag

# Install the tool, including development dependencies
pip install -e ".[dev]"
```

## Tests and linters

```bash
# Run the tests with coverage and all code linters
tox

# Run only the tests
tox -e test

# Run the tests and report coverage
tox -e test-with-coverage

# Run only the code linters
tox -e code-linters

# Auto-format the code
tox -e autoformat
```

## Testing local changes

To try out your local changes on a running cluster, use the [`sync-to-cluster.sh`](tools/sync-to-cluster.sh)
helper. It overwrites the tool's source dir on the head node with this local copy.

```bash
./tools/sync-to-cluster.sh my-cluster us-east-1 ~/.ssh/my-key.pem
```
