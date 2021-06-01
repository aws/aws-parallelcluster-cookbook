v2.6.4
------

* @Vancelot11 - added CentOS 8 support

v2.6.3
------

* Small tweak to Chef 13 compatible sysctl resources

v2.6.2
------

* Set lockd ports on Debian 8 and Ubuntu 14.04 via
  sysctl settings.

v2.6.1
------

* Updated to support Chef 14+ with builtin sysctl resource
* Dropped sysctl cookbook dependency, but maintained backwards
  compatibility by using file/execute resources for Chef 13

v2.6.0
------

* #107 - Bump line dependency version to 2.x

v2.5.1
------

* Set minimum supported Chef to 13.2.20
* Bump line and sysctl dependency versions


v2.5.0
------

* @chuhn - Add Debian Stretch support
* Updates to raise Supermarket metrics

v2.4.1
------

* Correct #95 regression on v2.4.0

v2.4.0
------

* Fixes #99 - Remove include_attribute 'sysctl' to maintain compatibility with
  sysctl cookbook changes.

v2.3.2
------

* Fixes #93 - nfs-idmap.service unit file depends on nfs-server.service provided
  by nfs-kernel-server package on Ubuntu 16.04.

v2.3.1
------

* Fixes #91 - nfs-config.service needs managed to apply fixed port configuration on
  Ubuntu 16.04 and CentOS 7.2

v2.3.0
------

* Fix #89 - Set sysctl parameters, only if nfs kernel module is loaded.
* Closes #76 - Remove service provider mapping, deferring to Chef 12 provider helpers.
* Fixes #81 - Re-instate status check.

v2.2.12
-------

* @nunukim
  - fix invalid /etc/defaults/nfs-kernel-server on Debian

v2.2.11
-------

* Ignore sysctl for OpenVZ/Virtuozzo
* Start rpcbind service in RHEL 7 prior to nfs server

v2.2.10
------

* Fix #69 - Logical condition error on CentOS 7
  - reported by @dougalb

v2.2.9
------

* @sspans
  - prevent resource duplication for shared configs
  - Rubocop fix-ups

* @hrak
  - Use systemd provider for Ubuntu >= 15.04

* @rlanore
  - Add knob to disable nfs v4

v2.2.8
------

* @zivagolee - Chef 11 backwards compatability for issues/source urls.

v2.2.7
------

* @gsreynolds
  - Add explicit service provider attributes for Debian, including Debian 8.

* @hrak
  - Use package portmap instead of rpcbind on Ubuntu <=13.04
  - Correct service name for Ubuntu <=13.04 = 'portmap', >=13.10 = 'rpcbind'


v2.2.6
------

* @davidgiesberg - fixed an issue with chef-client 12.5 in #67

v2.2.5
------

* @yoshiwaan - improved Amazon Linux platform support.
  - Also added tests, and example .kitchen.yml.aws file.

v2.2.4
------

* @shortgun corrected an Amazon Linux regression introduced by #57
* Cleaned out redundant BATS tests, in favor of Serverspec tests.
* Cleaned up Serverspec tests introduced by #57 to better reflect
  expected behavior.

v2.2.3
------

* @joerocklin added CentOS 7 support, and tests, in #57
* @sdrycroft added whitespace padding to replacement pattern in #62

v2.2.2
------

* Make service_provider edge cases an Ubuntu-specific hack.
  - More feedback may be needed on Debian platforms/versions
* CentOS platforms seem to detect service_provider fine, without
  explicitly setting one.
* Remove windows/solaris guard regression, because this should not be needed
  without overriding the service provider

v2.2.1
------

* Partial revert of service_provider Ubuntu hacks.

v2.2.0
------

* De-kludge service_provider hacks
* Add pattern parameter to looped service resources

v2.1.0
------

* @lmickh LWRP stairsteps anonids multiplicatively. #46
* @vgirnet added SLES init script failsafe. closes #47
* @StFS added EL7 service names. closes #39 #41 #49
* @stevenolen remove installation of nfs-kernel-server for debian platform. closes #43
* ChefSpec fixups
  - Runner deprecated.
  - Generic chefspec 0.6.1 platform has no service providers (i.e. sysvinit) in Chef.
  - FreeBSD mapping broken chef/chef#2383.

v2.0.0
------

* @jessp01 added rquotad support, Issue #34
* @jessp01 added NFS4 support, Issue #35
* @dudyk Hash Rockets, Issue #36
* @soul-rebel, Issue #37
* @kjtanaka, notification timing, Issue #38
* rework issue #35 to be cross-platform and backwards compatible
* fix tests, verify behavior
* Update documentation

**Potentially Breaking Changes**

Support for some versions of Ubuntu support unverified.  Please help cookbook
maintainers by submitting [fauxhai](https://github.com/customink/fauxhai) stub data
for your preferred platforms.

v1.0.0
------

* Removed unused variables from provider
* NFS server template refactored into singular template to take advantage
  of added features like `nfs['v4']` and `nfs['threads']`
* @eric-tucker added Amazon support
* @mvollrath added Ubuntu 13.10 support
* @JonathanSerafini added FreeBSD support
* @gswallow added an `nfs['threads']` attribute
* @brint added array support for network LWRP parameter
* Tests
  - @stuart12 added debian to kitchen.ci platforms
  - Chefspec unit test coverage
  - BATS integration  tests
  - Rubocop linting

v0.5.0
------

* @CloCkWeRX - LWRP multi-line fix
* @walbenzi - toggle-able nfs protocol level 2, or 3
  - defer to default proto level, and default behavior according to installed kernel
  - Add attributes to README

* @ranxxerox & @reoring - Debian wheezy support added

v0.4.2
------

Remove nfs::undo only upon conflict in run_list

v0.4.1
------

Community site version does not match cb on github.

v0.4.0
------

Add SLES 11 support.
Handle non-existent exports.
Re-order service/template.
Added attributes to LWRP for anonymous user and group mapping.
Removed deprecated exports documentation.
Add test-kitchen skeleton

v0.3.1
------

Correct LWRP behavior for empty exports file via @bryanwb

Corrected lint warnings:

    FC043: Prefer new notification syntax: ./recipes/default.rb:40
    FC043: Prefer new notification syntax: ./recipes/server.rb:35

v0.3.0
------

@someara exports LWRP refactor

* **Breaking changes**
  - Deprecated ~nfs['exports']~ attribute
  - remove exports recipe hack
* refactored provider to execute in new run_context
* update notification timings on exports resources
* add service status to recipes
* dependency and integration with [line](http://ckbk.it/line) editing
  cookbook

v0.2.8
------

Debian family attribute correction

Use portmap service when using the portmap package

v0.2.7
------

Documentation corrections
* correct node.nfs.port references
* correct run_list symtax

v0.2.6
------

Force float in platform_version conditional

v0.2.5
------

Ubutntu service names

* Fix Ubuntu 11.10 edge-case reported by Andrea Campi
* Update test cases

v0.2.4
------

Attribute typo for Debian

* Correct typo in attributes
* Add attribute testing for config templates
* Add /etc/exports grep for better idempotency guard

v0.2.3
------

* Fix service action typo in nfs::undo

v0.2.2
------

* [annoyance] Add run once nfs::undo recipe to stop and remove all nfs components
* Correct export duplication check in LWRP
* Re-factor attributes, and introduce Ubuntu 12+ edge cases
* Add testing artefacts for Travis CI integration

v0.2.0
------

* Add nfs_export LWRP, thanks Michael Ivey from Riot Games for the contribution
* Update README documentation, and add CHANGELOG

v0.1.0
------

* Re-factor NFS cookbook
* Add edge cases for RHEL6, thanks Bryan Berry for reporting and testing
* Filter-branched into cookbook-nfs repo

v0.0.6
------

* Add NFS export support
* Update documentation
* First community site release

v0.0.4
------

* Initial version with RHEL/CentOS/Debian/Ubuntu support
* Thanks to Glenn Pratt for testing on Debian family distros
