#
# slurm.sh:
#   Setup slurm environment variables
#

PATH=$PATH:<%= node['cluster']['slurm']['install_dir'] %>/bin
MANPATH=$MANPATH:<%= node['cluster']['slurm']['install_dir'] %>/share/man

export PATH MANPATH