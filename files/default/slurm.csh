
#
# slurm.csh:
#     Sets the C shell user environment for slurm commands
#
set path = ($path <%= node['cluster']['slurm']['install_dir'] %>/bin)
if ( ${?MANPATH} ) then
  setenv MANPATH ${MANPATH}:<%= node['cluster']['slurm']['install_dir'] %>/share/man
else
  setenv MANPATH :<%= node['cluster']['slurm']['install_dir'] %>/share/man
endif