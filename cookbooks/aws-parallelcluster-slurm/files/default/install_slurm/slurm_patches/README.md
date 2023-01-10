# Slurm patches configuration

This folder is for patch files for the Slurm source code. Patches must be produced by git
(e.g. via `git diff` or by downloading the diff from a commit in GitHub).

Patch files must be prepended with a zero-padded number in order to allow the cookbook to
apply the patches in a defined order. For example:
- 01_hashabc.diff
- 02_hashdef.diff
- 03 hash123.diff
