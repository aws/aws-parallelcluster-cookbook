# frozen_string_literal: true

property :backup, [true, false, Integer], default: false
property :delim, Array
property :ends_with, String
property :entry, String
property :eol, String
property :ignore_missing, [true, false], default: true
property :manage_symlink_source, [true, false]
property :path, String
property :pattern, [String, Regexp]

resource_name :add_to_list
provides :add_to_list
unified_mode true

action :edit do
  raise_not_found
  sensitive_default
  eol = default_eol
  backup_if_true
  current = target_current_lines
  manage_symlink_source_explicit = property_is_set?(:manage_symlink_source)

  # insert
  new = insert_list_entry(current)

  # eol on last line
  terminate_last_line(new, eol)

  file new_resource.path do
    content new.join(eol)
    manage_symlink_source new_resource.manage_symlink_source if manage_symlink_source_explicit
    backup new_resource.backup
    sensitive new_resource.sensitive
    not_if { new == current }
  end
end

action_class do
  include Line::Helper
  include Line::ListHelper
end
