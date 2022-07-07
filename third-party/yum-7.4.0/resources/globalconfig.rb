#
# Cookbook:: yum
# Resource:: repository
#
# Author:: Sean OMeara <someara@chef.io>
# Copyright:: 2013-2020, Chef Software, Inc.
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

# http://man7.org/linux/man-pages/man5/yum.conf.5.html

unified_mode true

property :alwaysprompt, [true, false], description: 'When true yum will not prompt for confirmation when the list of packages to be installed exactly matches those given on the command line. Unless assumeyes is enabled, it will prompt when additional packages need to be installed to fulfill dependencies regardless of this setting. Note that older versions of yum would also always prompt for package removal, and that is no longer true.'
property :assumeno, [true, false], description: "If yum would prompt for confirmation of critical actions, assume the user chose no. This is basically the same as doing 'echo | yum ...'  but is a bit more usable. This option overrides assumeyes, but is still subject to alwaysprompt."
property :assumeyes, [true, false], description: 'Determines whether or not yum prompts for confirmation of critical actions.'
property :autocheck_running_kernel, [true, false], description: "Set this to false to disable the automatic checking of the running kernel against updateinfo ('yum updateinfo check-running-kernel'), in the 'check-update' and 'updateinfo summary' commands."
property :autosavets, [true, false], description: 'Should yum automatically save a transaction to a file when the transaction is solved but not run. Yum defaults to True'
property :bandwidth, String, regex: /^\d+/, description: "Use to specify the maximum available network bandwidth in bytes/second. Used with the throttle property. If throttle is a percentage and bandwidth is '0' then bandwidth throttling will be disabled. If throttle is expressed as a data rate (bytes/sec) then this option is ignored."
property :best, [true, false], description: 'If enabled, the solver will either use a package with the highest available version or fail'
property :bugtracker_url, String, description: 'URL where bugs should be filed for yum. Configurable for local versions or distro-specific bugtrackers.'
property :cachedir, String, default: '/var/cache/yum/$basearch/$releasever', description: 'Directory where yum should store its cache and db files.'
property :cashe_root_dir, String, description: "Directory where yum would initialize the cashe, should almost certainly be left at the default. Yum's default is '/var/cache/CAShe'. Note that unlike all other configuration, this does not change with installroot, the reason is so that multiple install root can share the same data. See man cashe for more info."
property :check_config_file_age, [true, false], description: 'Specifies whether yum should auto metadata expire repos that are older than any of the configuration files that led to them (usually the yum.conf file and the foo.repo file).'
property :clean_requirements_on_remove, [true, false], description: "When removing packages (by removal, update or obsoletion) go through each package's dependencies. If any of them are no longer required by any other package then also mark them to be removed."
property :color, String, equal_to: %w(always never), description: 'Display colorized output automatically, depending on the output terminal'
property :color_list_available_downgrade, String
property :color_list_available_install, String
property :color_list_available_reinstall, String
property :color_list_available_upgrade, String
property :color_list_installed_extra, String
property :color_list_installed_newer, String
property :color_list_installed_older, String
property :color_list_installed_reinstall, String
property :color_search_match, String
property :color_update_installed, String
property :color_update_local, String
property :color_update_remote, String
property :commands, String, description: "List of functional commands to run if no functional commands are specified on the command line (eg. 'update foo bar baz quux'). None of the short options (eg. -y, -e, -d) are accepted for this option."
property :debuglevel, String, regex: /^\d+$/, default: '2', description: 'Debug message output level 0-10.'
property :deltarpm, [String, Integer], description: "When non-zero, delta-RPM files are used if available. The value specifies the maximum number of 'applydeltarpm' processes Yum will spawn, if the value is negative then yum works out how many cores you have and multiplies that by the value (cores=2, deltarpm=-2; 4 processes). (2 by default).\nNote that the 'applydeltarpm' process uses a significant amount of disk IO, so running too many instances can significantly slow down all disk IO including the downloads that yum is doing (thus. a too high value can make everything slower)."
property :deltarpm_metadata_percentage, String, description: "When the relative size of deltarpm metadata vs pkgs is larger than this, deltarpm metadata is not downloaded from the repo. Yum's default value is 100 (Deltarpm metadata must be smaller than the packages from the repo). Note that you can give values over 100, so 200 means that the metadata is required to be half the size of the packages. Use '0' to turn off this check, and always download metadata."
property :deltarpm_percentage, String, description: "When the relative size of delta vs pkg is larger than this, delta is not used. Yum's default value is 75 (Deltas must be at least 25% smaller than the pkg). Use '0' to turn off delta rpm processing. Local repositories (with file:// baseurl) have delta rpms turned off by default."
property :depsolve_loop_limit, Integer, description: "Set the number of times any attempt to depsolve before we just give up. This shouldn't be needed as yum should always solve or fail, however it has been observed that it can loop forever with very large system upgrades. Setting this to `0' (or " > ") makes yum try forever. Yum's default is '100'."
property :disable_excludes, [true, false], description: 'Permanently set the --disableexcludes command line option.'
property :diskspacecheck, [true, false], description: 'Set this to false to disable the checking for sufficient diskspace and inodes before a RPM transaction is run.'
property :distroverpkg, String, description: "The package used by yum to determine the 'version' of the distribution, this sets $releasever for use in config. files. This can be any installed package. Default is 'system-release(releasever)', 'redhat-release'. Yum will now look at the version provided by the provide, and if that is non-empty then will use the full V(-R), otherwise it uses the version of the package."
property :enable_group_conditionals, [true, false], description: 'Determines whether yum will allow the use of conditionals packages.'
property :errorlevel, String, regex: /^\d+$/, description: 'Error message output level 0-10.'
property :exactarch, [true, false], default: true
property :exactarchlist, String, description: "List of packages that should never change archs in an update.  That means, if a package has a newer version available which is for a different compatible arch, yum will not consider that version an update if the package name is in this list.  For example, on x86_64, foo-1.x86_64 won't be updated to foo-2.i686 if foo is in this list.  Kernels in particular fall into this category.  Shell globs using wildcards (eg. * and ?) are allowed."
property :exclude, String, description: "List of packages to exclude from all repositories, so yum works as if that package was never in the repositories. This should be a space separated list.  This is commonly used so a package isn't upgraded or installed accidentally, but can be used to remove packages in any way that 'yum list' will show packages.  Shell globs using wildcards (eg. * and ?) are allowed."
property :excludepkgs, String, description: 'Exclude packages from DNF specified by name or glob and separated by a comma. Can be disabled using disable_excludes.'
property :exit_on_lock, [true, false], description: 'Should the yum client exit immediately when something else has the lock. Yum defaults to false'
property :fssnap_abort_on_errors, String, equal_to: %w(), description: "When fssnap_automatic_pre or fssnap_automatic_post is enabled, it's possible to specify which fssnap errors should make the transaction fail. Yum's default is 'any'.\n'broken-setup' - Abort current transaction if snapshot support is unavailable because lvm is missing or broken.\n'snapshot-failure' - Abort current transaction if creating a snapshot fails (e.g. there is not enough free space to make a snapshot).\n'any' - Abort current transaction if any of the above occurs.\n'none' - Never abort a transaction in case of errors."
property :fssnap_automatic_keep, Integer, description: "How many old snapshots should yum keep when trying to automatically create a new snapshot. Setting to 0 disables this feature. Yum's default is '1'"
property :fssnap_automatic_post, [true, false], description: 'Should yum try to automatically create a snapshot after it runs a transaction. Yum defaults to False'
property :fssnap_automatic_pre, [true, false], description: 'Should yum try to automatically create a snapshot before it runs a transaction. Yum defaults to False'
property :fssnap_devices, String, description: 'The origin LVM devices to use for snapshots. Wildcards and negation are allowed, first match (positive or negative) wins.  Default is: !*/swap !*/lv_swap glob:/etc/yum/fssnap.d/*.conf'
property :fssnap_percentage, Integer, description: "The size of new snaphosts, expressed as a percentage of the old origin device.  Any number between 1 and 100. Yum defaults to '100'."
property :ftp_disable_epsv, [true, false], description: 'This options disables Extended Passive Mode (the EPSV command) which does not work correctly on some buggy ftp servers.'
property :gpgcheck, [true, false], default: true, description: 'This tells yum whether or not it should perform a GPG signature check on packages. When this is set in the [main] section it sets the default for all repositories.'
property :group_command, String, equal_to: %w(simple compat objects), description: "Tells yum what to do for group install/upgrade/remove commands.\nSimple acts like you did yum group cmd $(repoquery --group --list group), so it is very easy to reason about what will happen. Alas. this is often not what people want to happen.\nCompat. works much like simple, except that when you run 'group upgrade' it actually runs 'group install' (this means that you get any new packages added to the group, but you also get packages added that were there before and you didn't want). \nObjects makes groups act like a real object, separate from the packages they contain. Yum keeps track of the groups you have installed, so 'group upgrade' will install new packages for the group but not install old ones. It also knows about group members that are installed but weren't installed as part of the group, and won't remove those on 'group remove'.  Running 'yum upgrade' will also run 'yum group upgrade' (thus. adding new packages for all groups)."
property :group_package_types, String, description: "List of the following: optional, default, mandatory. Tells yum which type of packages in groups will be installed when 'groupinstall' is called."
property :groupremove_leaf_only, [true, false], description: "Used to determine yum's behaviour when the groupremove command is run. If groupremove_leaf_only is false (default) then all packages in the group will be removed. If groupremove_leaf_only is true then only those packages in the group that aren't required by another package will be removed."
property :history_list_view, String, equal_to: %w(users commands single-user-commands), description: "Which column of information to display in the 'yum history list' command."
property :history_record, [true, false], description: 'Should yum record history entries for transactions. This takes some disk space, and some extra time in the transactions. But it allows how to know a lot of information about what has happened before, and display it to the user with the history info/list/summary commands. yum also provides the history undo/redo commands.'
property :history_record_packages, String, description: 'This is a list of package names that should be recorded as having helped the transaction. yum plugins have an API to add themselves to this, so it should not normally be necessary to add packages here. Not that this is also used for the packages to look for in --version. Defaults to rpm, yum, yum-metadata-parser.'
property :http_caching, String, equal_to: %w(packages all none), description: "Determines how upstream HTTP caches are instructed to handle any HTTP downloads that Yum does. This option can take the following values: all' means that all HTTP downloads should be cached. 'packages' means that only RPM package downloads should be cached (but not repository metadata downloads). 'none' means that no HTTP downloads should be cached."
property :installonly_limit, String, regex: [/^\d+/, /keep/], default: '3', description: "Number of packages listed in installonlypkgs to keep installed at the same time. Setting to 0 disables this feature. Default is '0'. Note that this functionality used to be in the 'installonlyn' plugin, where this option was altered via tokeep.  Note that as of version 3.2.24, yum will now look in the yumdb for a installonly attribute on installed packages. If that attribute is 'keep', then they will never be removed."
property :installonlypkgs, String, description: 'List of package provides that should only ever be installed, never updated.  Kernels in particular fall into this category. Defaults to kernel, kernel-bigmem, kernel-enterprise, kernel-smp, kernel-modules, kernel-debug, kernel- unsupported, kernel-source, kernel-devel, kernel-PAE, kernel- PAE-debug.'
property :installroot, String, description: 'Specifies an alternative installroot, relative to which all packages will be installed.'
property :install_weak_deps, [true, false], description: "When this option is set to true and a new package is about to be installed, all packages linked by a weak dependency relation (i.e., Recommends or Supplements flags) with this package will be pulled into the transaction. Default is DNF's default of true."
property :ip_resolve, [String, Integer], equal_to: [4, '4', 6, '6'], description: "Determines how yum resolves host names. '4': resolve to IPv4 addresses only. '6': resolve to IPv6 addresses only."
property :keepalive, [true, false], description: 'Set whether HTTP keepalive should be used for HTTP/1.1 servers that support it. This can improve transfer speeds by using one connection when downloading multiple files from a repository.'
property :keepcache, [true, false], default: false, description: 'Determines whether or not yum keeps the cache of headers and packages after successful installation.'
property :kernelpkgnames, String, description: 'List of package names that are kernels. This is really only here for the updating of kernel packages and should be removed out in the yum 2.1 series.'
property :loadts_ignoremissing, [true, false], description: "Should the load-ts command ignore packages that are missing. This includes packages in the TS to be removed, which aren't installed, and packages in the TS to be added, which aren't available.  If this is set to true, and an rpm is missing then loadts_ignorenewrpm is automatically set to true. Yum defaults to False."
property :loadts_ignorenewrpm, [true, false], description: 'Should the load-ts command ignore the future rpmdb version or abort if there is a mismatch between the TS file and what will happen on the current machine.  Note that if loadts_ignorerpm is True, this option does nothing. Yum defaults to False'
property :loadts_ignorerpm, [true, false], description: 'Should the load-ts command ignore the rpmdb version (yum version nogroups) or abort if there is a mismatch between the TS file and the current machine.  If this is set to true, then loadts_ignorenewrpm is automatically set to true. Yum defaults to False'
property :localpkg_gpgcheck, [true, false], description: 'This tells yum whether or not it should perform a GPG signature check on local packages (packages in a file, not in a repositoy).'
property :logfile, String, default: '/var/log/yum.log', description: 'Full directory and file name for where yum should write its log file.'
property :max_connections, String, regex: /^\d+/, description: 'The maximum number of simultaneous connections.  This overrides the urlgrabber default of 5 connections. Note that there are also implicit per-mirror limits and the downloader honors these too.'
property :mddownloadpolicy, String, equal_to: %w(sqlite xml), description: "You can select which kinds of repodata you would prefer yum to download:\n'sqlite' - Download the .sqlite files, if available. This is currently slightly faster, once they are downloaded. However these files tend to be bigger, and thus. take longer to download. \n'xml' - Download the .XML files, which yum will do anyway as a fallback on the other options. These files tend to be smaller, but they require parsing/converting locally after download and some aditional checks are performed on them each time they are used."
property :mdpolicy, String, equal_to: %w(instant group:primary group:small group:main group:all), description: "You can select from different metadata download policies depending on how much data you want to download with the main repository metadata index. The advantages of downloading more metadata with the index is that you can't get into situations where you need to use that metadata later and the versions available aren't compatible (or the user lacks privileges) and that if the metadata is corrupt in any way yum will revert to the previous metadata.\n'instant' - Just download the new metadata index, this is roughly what yum always did, however it now does some checking on the index and reverts if it classifies it as bad.\n'group:primary' - Download the primary metadata with the index. This contains most of the package information and so is almost always required anyway.\n'group:small' - With the primary also download the updateinfo metadata, groups, and pkgtags. This is required for yum-security operations and it also used in the graphical clients. This file also tends to be significantly smaller than most others. This is the default. \n'group:main' - With the primary and updateinfo download the filelists metadata and the group metadata. The filelists data is required for operations like 'yum install /bin/bash', and also some dependency resolutions require it. The group data is used in some graphical clients and for group operations like 'yum grouplist Base'.\n'group:all' - Download all metadata listed in the index, currently the only one not listed above is the other metadata, which contains the changelog information which is used by yum-changelog. This is what 'yum makecache' uses."
property :metadata_expire, String, regex: [/^\d+$/, /^\d+[mhd]$/, /never/], description: "Time (in seconds) after which the metadata will expire. So that if the current metadata downloaded is less than this many seconds old then yum will not update the metadata against the repository. If you find that yum is not downloading information on updates as often as you would like lower the value of this option. You can also change from the default of using seconds to using days, hours or minutes by appending a d, h or m respectively. The default is 6 hours, to compliment yum-updatesd running once an hour. It's also possible to use the word 'never', meaning that the metadata will never expire. Note that when using a metalink file the metalink must always be newer than the metadata for the repository, due to the validation, so this timeout also applies to the metalink file."
property :metadata_expire_filter, String, equal_to: %w(never read-only:past read-only:present read-only:future), description: "Filter the metadata_expire time, allowing a trade of speed for accuracy if a command doesn't require it. Each yum command can specify that it requires a certain level of timeliness quality from the remote repos. from 'I\'m about to install/upgrade, so this better be current' to 'Anything that\'s available is good enough'. \n'never' - Nothing is filtered, always obey metadata_expire. \n'read-only:past' - Commands that only care about past\ information are filtered from metadata expiring.  Eg. yum history info (if history needs to lookup anything about a previous transaction, then by definition the remote package was available in the past). \n'read-only:present' - Commands that are balanced between past and future.  This is the default.  Eg. yum list yum\n'read-only:future' - Commands that are likely to result in running other commands which will require the latest metadata. Eg. yum check-update\nNote that this option requires that all the enabled repositories be roughly the same freshness (meaning the cache age difference from one another is at most 5 days).  Failing that, metadata_expire will always be obeyed, just like with 'never'.\nAlso note that this option does not override 'yum clean expire-cache'."
property :minrate, String, description: "This sets the low speed threshold in bytes per second. If the server is sending data slower than this for at least 'timeout' seconds, Yum aborts the connection."
property :mirrorlist_expire, String, regex: /^\d+$/, description: 'Time (in seconds) after which the mirrorlist locally cached will expire. If the current mirrorlist is less than this many seconds old then yum will not download another copy of the mirrorlist, it has the same extra format as metadata_expire. If you find that yum is not downloading the mirrorlists as often as you would like lower the value of this option.'
property :multilib_policy, String, equal_to: %w(all best), description: "The policy installation policy. Can be set to 'all' or 'best'. All means install all possible arches for any package you want to install. Therefore yum install foo will install foo.i386 and foo.x86_64 on x86_64, if it is available. Best means install the best arch for this platform, only. "
property :obsoletes, [true, false], description: "This option only has affect during an update. It enables yum's obsoletes processing logic. Useful when doing distribution level upgrades. See also the yum upgrade command documentation for more details"
property :options, Hash
property :override_install_langs, [true, false], description: "This is a way to override rpm's _install_langs macro. without having to change it within rpm's macro file"
property :overwrite_groups, [true, false], description: "Used to determine yum's behaviour if two or more repositories offer the package groups with the same name. If overwrite_groups is true then the group packages of the last matching repository will be used. If overwrite_groups is false then the groups from all matching repositories will be merged together as one large group.  Note that this option does not override remove_leaf_only, so enabling that option means this has almost no affect."
property :password, String, description: 'password to use with the username for basic authentication.'
property :path, String, name_property: true
property :persistdir, String, description: 'Directory where yum should store information that should persist over multiple runs.'
property :pluginconfpath, String, description: 'A list of directories where yum should look for plugin configuration files.'
property :pluginpath, String, description: 'A list of directories where yum should look for plugin modules.'
property :plugins, [true, false], default: true, description: 'Global switch to enable or disable yum plugins.'
property :protected_multilib, [true, false], description: 'This tells yum whether or not it should perform a check to make sure that multilib packages are the same version. For example, if this option is off (rpm behavior) then in some cases it might be possible for pkgA-1.x86_64 and pkgA-2.i386 to be installed at the same time. However this is very rarely desired. Install only packages, like the kernel, are exempt from this check.'
property :protected_packages, String, description: 'This is a list of packages that yum should never completely remove. They are protected via Obsoletes as well as user/plugin removals.'
property :proxy, String, description: 'URL to the proxy server that yum should use.'
property :proxy_password, String, description: 'The password for the specified proxy.'
property :proxy_username, String, description: 'The username for the specified proxy.'
property :query_install_excludes, [true, false], description: 'This applies the command line exclude option (only, not the configuration exclude above) to installed packages being shown in some query commands'
property :recent, String, regex: /^\d+$/, description: "Number of days back to look for 'recent' packages added to a repository."
property :recheck_installed_requires, [true, false], description: "When upgrading a package do we recheck any requirements that existed in the old package. Turning this on shouldn't do anything but slow yum depsolving down, however using rpm --nodeps etc. can break the rpmdb and then this will help."
property :releasever, String
property :remove_leaf_only, [true, false], description: "Used to determine yum's behaviour when a package is removed.  If remove_leaf_only is false then packages, and their deps, will be removed. If remove_leaf_only is true then only those packages that aren't required by another package will be removed."
property :repo_gpgcheck, [true, false], description: 'This tells yum whether or not it should perform a GPG signature check on the repodata. When this is set in the [main] section it sets the default for all repositories.'
property :repopkgsremove_leaf_only, [true, false], description: "Used to determine yum's behaviour when the repo-pkg remove command is run. If repopkgremove_leaf_only is false then all packages in the repo. will be removed. If repopkgremove_leaf_only is true then only those packages in the repo. that aren't required by another package will be removed.  Note that this option does not override remove_leaf_only, so enabling that option means this has almost no affect."
property :reposdir, String, description: "A list of directories where yum should look for .repo files which define repositories to use. Default is '/etc/yum/repos.d'. Each file in this directory should contain one or more repository sections as documented in [repository] options below. These will be merged with the repositories defined in /etc/yum/yum.conf to form the complete set of repositories that yum will use."
property :requires_policy, String, equal_to: %w(strong weak info), description: 'Strong means install just the needed requirements. Weak means also install any weak requirements. Info means install all requirements. This only happens on install/reinstall, upgrades/downgrades do not consult this at all.  Note that yum will try to just drop weak and info requirements on errors.'
property :reset_nice, [true, false], description: 'If set to true then yum will try to reset the nice value to zero, before running an rpm transaction.'
property :retries, String, regex: /^\d+$/, description: "Set the number of times any attempt to retrieve a file should retry before returning an error. Setting this to '0' makes yum try forever."
property :rpmverbosity, String, equal_to: %w(info critical emergency error warn debug), description: 'Debug scriptlet output level.'
property :shell_exit_status, String, equal_to: %w(0 ?), description: "Determines the exit status that should be returned by `yum shell' when it terminates after reading the `exit' command or EOF. If ? is set, the exit status is that of the last command executed before `exit' (bash-like behavior). Yum defaults to 0."
property :showdupesfromrepos, [true, false], description: 'Set to true if you wish to show any duplicate packages from any repository, from package listings like the info or list commands. Set to false if you want only to see the newest packages from any repository.'
property :skip_broken, [true, false], description: 'Resolve depsolve problems by removing packages that are causing problems from the transaction.'
property :skip_if_unavailable, [true, false], description: 'If enabled, DNF will continue running and disable any repository that could not be synchronized for any reason.'
property :skip_missing_names_on_install, [true, false], description: "If set to False, 'yum install' will fail if it can't find any of the provided names (package, group, rpm file). Yum's default is true."
property :skip_missing_names_on_update, [true, false], description: "If set to False, 'yum update' will fail if it can't find any of the provided names (package, group, rpm file). It will also fail if the provided name is a package which is available, but not installed. Yum's default is true."
property :ssl_check_cert_permissions, [true, false], description: "Whether yum should check the permissions on the paths for the certificates on the repository (both remote and local). If we can't read any of the files then yum will force skip_if_unavailable to be true. This is most useful for non-root processes which use yum on repos. that have client cert files which are readable only by root."
property :sslcacert, String, description: 'Path to the directory containing the databases of the certificate authorities yum should use to verify SSL certificates.'
property :sslclientcert, String, description: 'Path to the SSL client certificate yum should use to connect to repos/remote sites.'
property :sslclientkey, String, description: 'Path to the SSL client key yum should use to connect to repos/remote sites.'
property :sslverify, [true, false], description: 'Should yum verify SSL certificates/hosts at all.'
property :syslog_device, String, description: 'Where to log syslog messages. Can be a local device (path) or a host:port string to use a remote syslog. If empty or points to a nonexistent device, syslog logging is disabled.'
property :syslog_facility, String, description: 'Facility name for syslog messages.'
property :syslog_ident, String, description: 'Identification (program name) for syslog messages.'
property :throttle, String, regex: [/\d+k/, /\d+M/, /\d+G/], description: "Enable bandwidth throttling for downloads. This option can be expressed as a absolute data rate in bytes/sec. An SI prefix (k, M or G) may be appended to the bandwidth value (eg. '5.5k' is 5.5 kilobytes/sec, '2M' is 2 Megabytes/sec)."
property :timeout, String, regex: /^\d+$/, description: 'Number of seconds to wait for a connection before timing out.'
property :tolerant, [true, false], description: "If enabled, yum will go slower, checking for things that shouldn't be possible making it more tolerant of external errors.  Default to '0' (not tolerant)."
property :tsflags, String, description: "Comma or space separated list of transaction flags to pass to the rpm transaction set. These include 'noscripts', 'notriggers', 'nodocs', 'test', 'justdb' and 'nocontexts'. 'repackage' is also available but that does nothing with newer rpm versions. You can set all/any of them. However, if you don't know what these do in the context of an rpm transaction set you're best leaving it alone."
property :ui_repoid_vars, String, description: 'When a repository id is displayed, append these yum variables to the string if they are used in the baseurl/etc. Variables are appended in the order listed (and found).'
property :upgrade_group_objects_upgrade, [true, false], description: "Set this to false to disable the automatic running of 'group upgrade' when running the 'upgrade' command, and group_command is set to 'objects'."
property :upgrade_requirements_on_install, [true, false], description: "When installing/reinstalling/upgrading packages go through each package's installed dependencies and check for an update."
property :usercache, String, description: "Determines whether or not yum should store per-user cache in $TMPDIR.  When set to '0', then whenever yum runs as a non-root user, --cacheonly is implied and system cache is used directly, and no new user cache is created in $TMPDIR.  This can be used to prevent $TMPDIR from filling up if many users on the system often use yum and root tends to have up-to-date metadata that the users can rely on (they can still enable this feature with --setopt if they wish)."
property :username, String, description: 'username to use for basic authentication to a repo or really any url.'
property :usr_w_check, [true, false], description: "Set this to false to disable the checking for writability on /usr in the installroot (when going into the depsolving stage). Yum's default is true."

alias_method :max_retries, :retries

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
