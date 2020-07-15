#
# Cookbook:: yum
# Resource:: repository
#
# Author:: Sean OMeara <someara@chef.io>
# Copyright:: 2013-2017, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# http://linux.die.net/man/5/yum.conf
property :alwaysprompt, [true, false]
property :assumeyes, [true, false]
property :bandwidth, String, regex: /^\d+/
property :bugtracker_url, String, regex: /.*/
property :clean_requirements_on_remove, [true, false]
property :cachedir, String, regex: /.*/, default: '/var/cache/yum/$basearch/$releasever'
property :color, String, equal_to: %w(always never)
property :color_list_available_downgrade, String, regex: /.*/
property :color_list_available_install, String, regex: /.*/
property :color_list_available_reinstall, String, regex: /.*/
property :color_list_available_upgrade, String, regex: /.*/
property :color_list_installed_extra, String, regex: /.*/
property :color_list_installed_newer, String, regex: /.*/
property :color_list_installed_older, String, regex: /.*/
property :color_list_installed_reinstall, String, regex: /.*/
property :color_search_match, String, regex: /.*/
property :color_update_installed, String, regex: /.*/
property :color_update_local, String, regex: /.*/
property :color_update_remote, String, regex: /.*/
property :commands, String, regex: /.*/
property :debuglevel, String, regex: /^\d+$/, default: '2'
property :deltarpm, [true, false]
property :diskspacecheck, [true, false]
property :distroverpkg, String, regex: /.*/
property :enable_group_conditionals, [true, false]
property :errorlevel, String, regex: /^\d+$/
property :exactarch, [true, false], default: true
property :exclude, String, regex: /.*/
property :gpgcheck, [true, false], default: true
property :group_package_types, String, regex: /.*/
property :groupremove_leaf_only, [true, false]
property :history_list_view, String, equal_to: %w(users commands single-user-commands)
property :history_record, [true, false]
property :history_record_packages, String, regex: /.*/
property :http_caching, String, equal_to: %w(packages all none)
property :installonly_limit, String, regex: [/^\d+/, /keep/], default: '3'
property :installonlypkgs, String, regex: /.*/
property :installroot, String, regex: /.*/
property :keepalive, [true, false]
property :keepcache, [true, false], default: false
property :kernelpkgnames, String, regex: /.*/
property :localpkg_gpgcheck, [true, false]
property :logfile, String, regex: /.*/, default: '/var/log/yum.log'
property :max_retries, String, regex: /^\d+$/
property :mdpolicy, String, equal_to: %w(instant group:primary group:small group:main group:all)
property :metadata_expire, String, regex: [/^\d+$/, /^\d+[mhd]$/, /never/]
property :mirrorlist_expire, String, regex: /^\d+$/
property :multilib_policy, String, equal_to: %w(all best)
property :obsoletes, [true, false]
property :overwrite_groups, [true, false]
property :password, String, regex: /.*/
property :path, String, regex: /.*/, name_property: true
property :persistdir, String, regex: /.*/
property :pluginconfpath, String, regex: /.*/
property :pluginpath, String, regex: /.*/
property :plugins, [true, false], default: true
property :protected_multilib, [true, false]
property :protected_packages, String, regex: /.*/
property :proxy, String, regex: /.*/
property :proxy_password, String, regex: /.*/
property :proxy_username, String, regex: /.*/
property :recent, String, regex: /^\d+$/
property :releasever, String, regex: /.*/
property :repo_gpgcheck, [true, false]
property :reposdir, String, regex: /.*/
property :reset_nice, [true, false]
property :rpmverbosity, String, equal_to: %w(info critical emergency error warn debug)
property :showdupesfromrepos, [true, false]
property :skip_broken, [true, false]
property :ssl_check_cert_permissions, [true, false]
property :sslcacert, String, regex: /.*/
property :sslclientcert, String, regex: /.*/
property :sslclientkey, String, regex: /.*/
property :sslverify, [true, false]
property :syslog_device, String, regex: /.*/
property :syslog_facility, String, regex: /.*/
property :syslog_ident, String, regex: /.*/
property :throttle, String, regex: [/\d+k/, /\d+M/, /\d+G/]
property :timeout, String, regex: /^\d+$/
property :tolerant, [true, false]
property :tsflags, String, regex: /.*/
property :username, String, regex: /.*/
property :options, Hash

action :create do
  template new_resource.path do
    source 'main.erb'
    cookbook 'yum'
    mode '0644'
    variables(config: new_resource)
  end
end

action :delete do
  file new_resource.path do
    action :delete
  end
end
