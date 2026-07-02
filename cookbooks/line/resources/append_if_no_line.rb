# frozen_string_literal: true

property :backup, [true, false, Integer], default: false
property :eol, String
property :group, String
property :ignore_missing, [true, false], default: true
property :line, String
property :manage_symlink_source, [true, false]
property :mode, [String, Integer]
property :owner, String
property :path, String

resource_name :append_if_no_line
provides :append_if_no_line
unified_mode true

action :edit do
  raise_not_found
  sensitive_default
  eol = default_eol
  backup_if_true
  add_line = chomp_eol(new_resource.line)
  string = Regexp.escape(add_line)
  regex = /^#{string}$/
  current = target_current_lines
  manage_symlink_source_explicit = property_is_set?(:manage_symlink_source)

  file new_resource.path do
    content((current + [add_line + eol]).join(eol))
    owner new_resource.owner
    group new_resource.group
    mode new_resource.mode
    manage_symlink_source new_resource.manage_symlink_source if manage_symlink_source_explicit
    backup new_resource.backup
    sensitive new_resource.sensitive
    not_if { ::File.exist?(new_resource.path) && !current.grep(regex).empty? }
  end
end

action_class do
  include Line::Helper
end
