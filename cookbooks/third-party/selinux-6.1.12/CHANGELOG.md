# selinux Cookbook CHANGELOG

This file is used to list changes made in each version of the selinux cookbook.

## 6.1.12 - *2023-05-17*

## 6.1.11 - *2023-04-17*

## 6.1.10 - *2023-04-07*

Standardise files with files in sous-chefs/repo-management

## 6.1.9 - *2023-04-01*

## 6.1.8 - *2023-04-01*

## 6.1.7 - *2023-04-01*

Standardise files with files in sous-chefs/repo-management

## 6.1.6 - *2023-03-20*

Standardise files with files in sous-chefs/repo-management

## 6.1.5 - *2023-03-15*

Standardise files with files in sous-chefs/repo-management

## 6.1.4 - *2023-02-23*

Standardise files with files in sous-chefs/repo-management

## 6.1.3 - *2023-02-15*

## 6.1.2 - *2023-02-14*

Standardise files with files in sous-chefs/repo-management

## 6.1.1 - *2023-02-03*

- Updated selinux_port documentation

## 6.1.0 - *2023-01-18*

- resolved cookstyle error: resources/install.rb:5:1 refactor: `Chef/Style/CopyrightCommentFormat`
- resolved cookstyle error: resources/module.rb:5:1 refactor: `Chef/Style/CopyrightCommentFormat`
- resolved cookstyle error: resources/state.rb:5:1 refactor: `Chef/Style/CopyrightCommentFormat`
- Standardise files with files in sous-chefs/repo-management
- Add `selinux_login` resource
- Add `selinux_user` resource

## 6.0.7 - *2022-11-01*

- Fix CentOS 6 package requirements
- Fix Chef 18 compatibility

## 6.0.6 - *2022-09-28*

- Add missing `policycoreutils-python` package
- Include additional platforms and suites for testing
- Run `apt_update` in `selinux_install` on Debian-based systems
- Fix SELinux enablement on Ubuntu 18.04

## 6.0.5 - *2022-09-18*

- Standardise files with files in sous-chefs/repo-management
- Add testing for Debian 11, Alma Linux and Rocky Linux
- Remove testing for CentOS 8 (prefer Stream instead)
- Update Github CI config

## 6.0.4 - *2022-02-17*

- Standardise files with files in sous-chefs/repo-management

## 6.0.3 - *2022-02-08*

- Remove delivery folder

## 6.0.2 - *2022-01-01*

- resolved cookstyle error: resources/install.rb:5:1 refactor: `Chef/Style/CopyrightCommentFormat`
- resolved cookstyle error: resources/module.rb:5:1 refactor: `Chef/Style/CopyrightCommentFormat`
- resolved cookstyle error: resources/state.rb:5:1 refactor: `Chef/Style/CopyrightCommentFormat`

## 6.0.1 - *2021-11-03*

- Correctly parse ports with multple contexts

## 6.0.0 - *2021-09-02*

- Import `selinux_policy` resources into this cookbook (`_fcontext`, `_permissive`, and `_port`)
- `selinux_policy_module` not imported since it is a duplicate of `selinux_module`

### Deprecations

- `selinux_fcontext` action `addormodify` renamed to `manage`
- `selinux_port` action `addormodify` renamed to `manage`

## 5.1.1 - *2021-08-30*

- Standardise files with files in sous-chefs/repo-management

## 5.1.0 - *2021-08-21*

- Fix `selinux_install` on Alma Linux / Oracle Linux

## 5.0.0 - *2021-08-10*

### Note: With version 5.0.0 the default recipe has been removed

- Major refactoring
- Restore support for Debian based distros
- All resources now use unified_mode
- Added selinux_boolean resource
- Remove attributes and default recipe
- Replaced with a set of bare recipes for the three selinux states
- Add automatic restart function to `selinux_state` resource

## 4.0.0 - *2021-07-21*

- Sous Chefs adoption
- Enable `unified_mode` for Chef 17 compatibility
- Update test platforms

## 3.1.1 (2020-09-29)

- Move `default['selinux']['status']` attribute to `default['selinux']['state']` to avoid conflicts with Ohai in Chef Infra Client 16 - [@shoekstra](https://github.com/shoekstra)

## 3.1.0 (2020-09-29)

- Cookstyle Bot Auto Corrections with Cookstyle 6.16.8 - [@cookstyle](https://github.com/cookstyle)
- Add a new `node['selinux']['install_mcstrans_package']` attribute to control installation of the mcdtrans package. This default to true to maintain existing functionality. - [@kapilchouhan99](https://github.com/kapilchouhan99)

## 3.0.2 (2020-08-25)

- Fix failures in CI- [@shoekstra](https://github.com/shoekstra)
- Specify platform to SoloRunner - [@shoekstra](https://github.com/shoekstra)
- Remove unnecessary Foodcritic comments - [@tas50](https://github.com/tas50)
- Notify :immediately not :immediate - [@tas50](https://github.com/tas50)
- Add Github actions testing of style/unit - [@tas50](https://github.com/tas50)
- [GH-67] - Do not try to modify frozen checksum - [@vzDevelopment](https://github.com/vzDevelopment)
- Standardise files with files in chef-cookbooks/repo-management - [@xorimabot](https://github.com/xorimabot)

## 3.0.1 (2019-11-14)

- Remove the deprecated ChefSpec report - [@tas50](https://github.com/tas50)
- Allow "-" and "_" for module names - [@ramereth](https://github.com/ramereth)
- Update Fedora versions we test on - [@tas50](https://github.com/tas50)

## 3.0.0 (2019-06-06)

- Support for SELinux Modules, via new resource `selinux_module`, able to compile `.te` files, install and remove modules;
- Improving test coverage for all resources
- Remove support for Ubuntu/Debian
- Require Chef 13+

## 2.1.1 (2018-06-07)

- Do not execute setenforce 1 always
- Remove chefspec matchers that are autogenerated now
- Chef 13 Fixes

## 2.1.0 (2017-09-15)

- Simplify Travis config and fix ChefDK 2.0 failures
- Use bento slugs in Kitchen
- Remove maintainer files
- More cleanup of the maintainer files
- Speed up install with multi-package install

## 2.0.3 (2017-06-13)

- Fix boolean check within default recipe

## 2.0.2 (2017-06-05)

- Permissive guard should grep for permissive not just disabled

## 2.0.1 (2017-05-30)

- Remove class_eval usage

## 2.0.0 (2017-05-15)

- Deprecate debian family support
- Make default for rhel family use setenforce regardless of whether a temporary change or not. Eliminates the requirement for a required reboot to effect change in the running system.

## 1.0.4 (2017-04-17)

- Switch to local delivery for testing
- Use the standard apache license string
- Updates for early Chef 12 and Chef 13 compatibility
- Update and add copyright blocks to the various files

## 1.0.3 (2017-03-14)

- Fix requirement in metadata to reflect need for Chef 12.7 as using action_class in state resource.

## 1.0.2 (2017-03-01)

- Remove setools* packages from install resource (utility to analyze and query policies, monitor and report audit logs, and manage file context). Future versions of this cookbook that might use this need to handle package install on Oracle Linux as not available in default repo.

## 1.0.1 (2017-02-26)

- Fix logic error in the permissive state change

## 1.0.0 (2017-02-26)

- **BREAKING CHANGE** `node['selinux']['state']` is now `node['selinux']['status']` to meet Chef 13 requirements.
- Update to current cookbook engineering standards
- Rewrite LWRP to 12.5 resources
- Resolved cookstyle errors
- Update package information for debian based on <https://debian-handbook.info/browse/stable/sect.selinux.html>
- selinux-activate looks like it's required to ACTUALLY activate selinux on non-RHEL systems. This seems like it could be destructive if unexpected.

- Add property temporary to allow for switching between permissive and enabled

- Add install resource

## v0.9.0 (2015-02-22)

- Initial Debian / Ubuntu support
- Various bug fixes

## v0.8.0 (2014-04-23)

- [COOK-4528] - Fix selinux directory permissions
- [COOK-4562] - Basic support for Ubuntu/Debian

## v0.7.2 (2014-03-24)

handling minimal installs

## v0.7.0 (2014-02-27)

[COOK-4218] Support setting SELinux boolean values

## v0.6.2

- Fixing bug introduced in 0.6.0
- adding basic test-kitchen coverage

## v0.6.0

- [COOK-760] - selinux enforce/permit/disable based on attribute

## v0.5.6

- [COOK-2124] - enforcing recipe fails if selinux is disabled

## v0.5.4

- [COOK-1277] - disabled recipe fails on systems w/o selinux installed

## v0.5.2

- [COOK-789] - fix dangling commas causing syntax error on some rubies

## v0.5.0

- [COOK-678] - add the selinux cookbook to the repository
- Use main selinux config file (/etc/selinux/config)
- Use getenforce instead of selinuxenabled for enforcing and permissive
