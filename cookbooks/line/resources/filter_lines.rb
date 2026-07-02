# frozen_string_literal: true

#
# Copyright::  2019 Sous Chefs
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

property :backup, [true, false, Integer], default: false
property :eol, String
property :filters, [Array, Hash, Method, Proc], required: true
property :ignore_missing, [true, false], default: true
property :manage_symlink_source, [true, false]
property :path, String, name_property: true
property :safe, [true, false], default: true

resource_name :filter_lines
provides :filter_lines
unified_mode true

action :edit do
  raise_not_found
  sensitive_default
  eol = default_eol
  backup_if_true

  current = ::File.exist?(new_resource.path) ? ::File.binread(new_resource.path).split(eol) : []
  @new = current.clone
  manage_symlink_source_explicit = property_is_set?(:manage_symlink_source)

  # Proc or Method
  # if new_resource.filter.is_a?(Method) || new_resource.filter.is_a?(Proc)
  #  new = new_resource.filter.call(new, new_resource.filter_args)
  # end

  # Filters - grammar
  #
  # filters ::= filter | [<filter>, ...]
  # filter ::= <code> | { <code> => <args> }
  # args ::= <String> | <Array>
  # code ::= <Symbol> | <Method> | <Proc>
  # Symbol ::= :after | :before | :between | :comment | :delete_between | :missing | :replace | :replace_between | :stanza | :substitute
  # Method ::= A reference to a method that has a signature of method(current lines is Array, args is Array) and returns an array
  # Proc ::= A reference to a proc that has a signature of proc(current lines is Array, args is Array) and returns an array
  #
  # Symbols will be translated to a method in Line::Filter
  case new_resource.filters
  when Array
    new_resource.filters.each do |filter|
      apply_filter(filter)
    end
  when NilClass
    false
  else
    apply_filter(new_resource.filters)
  end

  # eol on last line
  terminate_last_line(@new, eol)
  terminate_last_line(current, eol)
  new = @new

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
end
