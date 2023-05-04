# nfs Cookbook CHANGELOG

This file is used to list changes made in each version of the nfs cookbook.

## 5.0.0 - *2021-11-01*

- Sous Chefs adoption
- Loosen version pin on line cookbook
- Fix CentOS 8+ and Fedora and properly manage /etc/nfs.conf
- Add `fsid` property to the `nfs_export` resource
- Fix services that are loaded
- Switch to using `kernel_module` resource for lockd module
- Fix idempotency with sysctl resource usage

## 4.0.0 - *2021-09-11*

This release adds support for Chef 17 and modernizes syntax and tooling.

- **BREAKING**
  - Drop support for Chef version < 15.3
- Chef 17 compatibility
  - Enable unified_mode for custom resources
- Cookbook Cleanup
  - Cookstyle fixes
  - LWRP -> custom resource conversion
  - Update to new spec test format
  - Move test cookbook to standard location
  - Move kitchen files to standard location
  - Convert integration testing to InSpec

## 3.0.0 - *2020-11-04*

This release unifies systemd based NFS systems. Much of the platform branching has been removed dropping support for System V initialized NFS servers.

- **BREAKING**
  - Added
    - Debian 10
    - Ubuntu 18.04
    - Ubuntu 20.04
    - CentOS/RHEL 8
  - Dropped
    - Debian 8
    - Debian 9
    - CentOS/RHEL 5
    - CentOS/RHEL 6
    - Ubuntu 14.04
  - Iffy (not supported)
    - SUSE
    - FreeBSD

- @rexcsn - corrected nfs-idmap service name
- Set default_env so exportfs can be found under Chef 14.2+

## 2.6.4 - *2020-02-27*

- @Vancelot11 - added CentOS 8 support

## 2.6.3 - *2018-11-07*

- Small tweak to Chef 13 compatible sysctl resources

## 2.6.2 - *2018-08-27*

- Set lockd ports on Debian 8 and Ubuntu 14.04 via sysctl settings.

## 2.6.1 - *2018-08-24*

- Updated to support Chef 14+ with builtin sysctl resource
- Dropped sysctl cookbook dependency, but maintained backwards compatibility by using file/execute resources for Chef 13

## 2.6.0 - *2018-08-23*

- #107 - Bump line dependency version to 2.x

## 2.5.1 - *2018-04-27*

- Set minimum supported Chef to 13.2.20
- Bump line and sysctl dependency versions

## 2.5.0 - *2017-12-05*

- @chuhn - Add Debian Stretch support
- Updates to raise Supermarket metrics

## 2.4.1 - *2017-08-08*

- Correct #95 regression on v2.4.0

## 2.4.0 - *2017-08-07*

- Fixes #99 - Remove include_attribute 'sysctl' to maintain compatibility with sysctl cookbook changes.

## 3.3.3 - *2017-05-08*

- Remove trailing newline from export line. Closes #95

## 2.3.2 - *2017-01-10*

- Fixes #93 - nfs-idmap.service unit file depends on nfs-server.service provided by nfs-kernel-server package on Ubuntu
  16.04.

## 2.3.1 - *2016-12-09*

- Fixes #91 - nfs-config.service needs managed to apply fixed port configuration on Ubuntu 16.04 and CentOS 7.2

## 2.3.0 - *2016-10-24*

- Fix #89 - Set sysctl parameters, only if nfs kernel module is loaded.
- Closes #76 - Remove service provider mapping, deferring to Chef 12 provider helpers.
- Fixes #81 - Re-instate status check.

## 2.2.12 - *2016-10-07*

- @nunukim
  - fix invalid /etc/defaults/nfs-kernel-server on Debian

## 2.2.11 - *2016-09-22*

- Ignore sysctl for OpenVZ/Virtuozzo
- Start rpcbind service in RHEL 7 prior to nfs server

## 2.2.10 - *2016-08-11*

- Fix #69 - Logical condition error on CentOS 7
  - reported by @dougalb

## 2.2.9 - *2016-08-11*

- @sspans
  - prevent resource duplication for shared configs
  - Rubocop fix-ups

- @hrak
  - Use systemd provider for Ubuntu >= 15.04

- @rlanore
  - Add knob to disable nfs v4

## 2.2.8 - *2016-04-27*

- @zivagolee - Chef 11 backwards compatability for issues/source urls.

## 2.2.7 - *2016-04-21*

- @gsreynolds
  - Add explicit service provider attributes for Debian, including Debian 8.

- @hrak
  - Use package portmap instead of rpcbind on Ubuntu <=13.04
  - Correct service name for Ubuntu <=13.04 = 'portmap', >=13.10 = 'rpcbind'

## 2.2.6 - *2015-10-14*

- @davidgiesberg - fixed an issue with chef-client 12.5 in #67

## 2.2.5 - *2015-08-11*

- @yoshiwaan - improved Amazon Linux platform support.
  - Also added tests, and example .kitchen.yml.aws file.

## 2.2.4 - *2015-07-09*

- @shortgun corrected an Amazon Linux regression introduced by #57
- Cleaned out redundant BATS tests, in favor of Serverspec tests.
- Cleaned up Serverspec tests introduced by #57 to better reflect expected behavior.

## 2.2.3 - *2015-07-08*

- @joerocklin added CentOS 7 support, and tests, in #57
- @sdrycroft added whitespace padding to replacement pattern in #62

## 2.2.2 - *2015-07-01*

- Make service_provider edge cases an Ubuntu-specific hack.
  - More feedback may be needed on Debian platforms/versions
- CentOS platforms seem to detect service_provider fine, without explicitly setting one.
- Remove windows/solaris guard regression, because this should not be needed without overriding the service provider

## 2.2.1 - *2015-06-29*

- Partial revert of service_provider Ubuntu hacks.

## 2.2.0 - *2015-06-29*

- De-kludge service_provider hacks
- Add pattern parameter to looped service resources

## 2.1.0 - *2015-02-13*

- @lmickh LWRP stairsteps anonids multiplicatively. #46
- @vgirnet added SLES init script failsafe. closes #47
- @StFS added EL7 service names. closes #39 #41 #49
- @stevenolen remove installation of nfs-kernel-server for debian platform. closes #43
- ChefSpec fixups
  - Runner deprecated.
  - Generic chefspec 0.6.1 platform has no service providers (i.e. sysvinit) in Chef.
  - FreeBSD mapping broken chef/chef#2383.

## 2.0.0 - *2014-06-14*

- @jessp01 added rquotad support, Issue #34
- @jessp01 added NFS4 support, Issue #35
- @dudyk Hash Rockets, Issue #36
- @soul-rebel, Issue #37
- @kjtanaka, notification timing, Issue #38
- rework issue #35 to be cross-platform and backwards compatible
- fix tests, verify behavior
- Update documentation

### Potentially Breaking Changes

Support for some versions of Ubuntu support unverified.  Please help cookbook maintainers by submitting [fauxhai](https://github.com/customink/fauxhai) stub data for your preferred platforms.

## 1.0.0 - *2014-05-20*

- Removed unused variables from provider
- NFS server template refactored into singular template to take advantage of added features like `nfs['v4']` and `nfs['threads']`
- @eric-tucker added Amazon support
- @mvollrath added Ubuntu 13.10 support
- @JonathanSerafini added FreeBSD support
- @gswallow added an `nfs['threads']` attribute
- @brint added array support for network LWRP parameter
- Tests
  - @stuart12 added debian to kitchen.ci platforms
  - Chefspec unit test coverage
  - BATS integration  tests
  - Rubocop linting

## 0.5.0 - *2013-09-06*

- @CloCkWeRX - LWRP multi-line fix
- @walbenzi - toggle-able nfs protocol level 2, or 3
  - defer to default proto level, and default behavior according to installed kernel
  - Add attributes to README

- @ranxxerox & @reoring - Debian wheezy support added

## 0.4.2 - *2013-07-16*

- Remove nfs::undo only upon conflict in run_list

## 0.4.1 - *2013-06-24*

- Community site version does not match cb on github.

## 0.4.0 - *2013-06-06*

- Add SLES 11 support.
- Handle non-existent exports.
- Re-order service/template.
- Added attributes to LWRP for anonymous user and group mapping.
- Removed deprecated exports documentation.
- Add test-kitchen skeleton

## 0.3.1 - *2013-01-14*

- Correct LWRP behavior for empty exports file via @bryanwb
- Corrected lint warnings:

  - FC043: Prefer new notification syntax: ./recipes/default.rb:40
  - FC043: Prefer new notification syntax: ./recipes/server.rb:35

## 0.3.0 - *2012-12-10*

@someara exports LWRP refactor

- **Breaking changes**
  - Deprecated ~nfs['exports']~ attribute
  - remove exports recipe hack
- refactored provider to execute in new run_context
- update notification timings on exports resources
- add service status to recipes
- dependency and integration with [line](http://ckbk.it/line) editing cookbook

## 0.2.8 - *2012-11-28*

- Debian family attribute correction
- Use portmap service when using the portmap package

## 0.2.7 - *2012-09-26*

- Documentation corrections
  - correct node.nfs.port references
  - correct run_list symtax

## 0.2.6 - *2012-08-14*

- Force float in platform_version conditional

## 0.2.5 - *2012-08-13*

Ubuntu service names

- Fix Ubuntu 11.10 edge-case reported by Andrea Campi
- Update test cases

## 0.2.4 - *2012-06-13*

Attribute typo for Debian

- Correct typo in attributes
- Add attribute testing for config templates
- Add /etc/exports grep for better idempotency guard

## 0.2.3 - *2012-05-24*

- Fix service action typo in nfs::undo

## 0.2.2 - *2012-05-22*

- [annoyance] Add run once nfs::undo recipe to stop and remove all nfs components
- Correct export duplication check in LWRP
- Re-factor attributes, and introduce Ubuntu 12+ edge cases
- Add testing artefacts for Travis CI integration

## 0.2.0 - *2012-05-01*

- Add nfs_export LWRP, thanks Michael Ivey from Riot Games for the contribution
- Update README documentation, and add CHANGELOG

## 0.1.0 - *2012-04-17*

- Re-factor NFS cookbook
- Add edge cases for RHEL6, thanks Bryan Berry for reporting and testing
- Filter-branched into cookbook-nfs repo

## 0.0.6 - *2011-07-08*

- Add NFS export support
- Update documentation
- First community site release

## 0.0.4 - *2011-07-01*

- Initial version with RHEL/CentOS/Debian/Ubuntu support
- Thanks to Glenn Pratt for testing on Debian family distros
