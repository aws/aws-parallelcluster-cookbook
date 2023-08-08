if platform_family?('debian')
  # Ubuntu breaks kitchen SSH connections by default so need to load a module or two first
  include_recipe 'selinux::permissive'
else
  include_recipe 'selinux::enforcing'
end
