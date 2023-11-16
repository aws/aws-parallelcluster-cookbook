# pyenv Changelog

## 4.2.3 - *2023-06-08*

## 4.2.2 - *2023-06-08*

Standardise files with files in sous-chefs/repo-management

## 4.2.1 - *2023-02-02*

- Update `templates/pyenv.sh` script to properly evaluate when to add a user install to `$PATH`

## 4.2.0 - *2022-09-26*

- Add support for ubuntu >= 22.04 and debian >= 11

## 4.1.0 - *2022-07-20*

- Remove duplicate pyenv init from profile script, fixes "pyenv: cannot rehash: <...>/shims isn't writable" for system install

## 4.0.1 - *2022-02-08*

- Remove delivery folder

## 4.0.0 - *2021-12-20*

- Set unified_mode for Chef 17 support
- Require Chef 15.3 for unified_mode
- Fix pyenv not being on the path properly
- resolved cookstyle error: resources/global.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
- resolved cookstyle error: resources/pip.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
- resolved cookstyle error: resources/plugin.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
- resolved cookstyle error: resources/python.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
- resolved cookstyle error: resources/rehash.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
- resolved cookstyle error: resources/script.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
- resolved cookstyle error: resources/system_install.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
- resolved cookstyle error: resources/user_install.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
- Removed the pyenv_system_install and pyenv_user_install resources for a singular pyenv_install.

   - This resource acts like all other resources where it can install both as a user and system wide.
     Please see the documentation for further information.

## 3.5.1 - *2021-08-30*

- Standardise files with files in sous-chefs/repo-management

## 3.5.0 - *2021-07-22*

- Add support for setting umask for pip resource.

## 3.4.2 - *2021-06-01*

- Standardise files with files in sous-chefs/repo-management

## 3.4.1 - *2020-12-31*

- resolved cookstyle error: resources/pip.rb:153:1 convention: `Layout/TrailingEmptyLines`

## 3.4.0 (2020-11-05)

- Add `:upgrade` action to the pyenv_pip resource

## 3.3.2 (2020-08-05)

- Do not attempt to rehash in a system-wide install
- Removed testing support for centos-6. Python 3.7.1 requires a newer version of openssl than centos-6 supplies.
- Removed testing support for debian-8. Debian-8 is no longer supported. Also has issues with the level of openssl that is available.

## 3.3.1

- Namespace the run_state variables used in the resources

## 3.3.0

- Chef 16 removed defaults for checkout_branch from the git resource, restore them to the previous default 'deploy'

## 3.2.0

- resolved cookstyle error: resources/pip.rb:107:7 convention: `Style/RedundantReturn`
- resolved cookstyle error: resources/pip.rb:110:7 convention: `Style/RedundantReturn`
- Migrate to actions for builds
- Fix broken link in README
- Follow up tweaks after ownership migration

## 3.1.1

- Migrated ownership to Sous-Chefs
- Latest cookstyle fixes (5.9.3)

## 3.1.0

- invoke `pip install` only necessary #34

## 3.0.0

- deprecate support for Chef 13 due to [EOL][supported-versions]
- update cookbook to use `apt_update` and `build_essential` resources from Chef 14 make sure builds don't failed because of lack of packages

## 2.1.0

- add support for virtualenv installation and uninstallation.
- add support for passing environment variable during pyenv, python and plugin installation.
- delete "reinstall" property from pip resource and replace it with general "options" property
- make pyenv_script fail on any subcommand failure

Thanks to [@ssps](https://github.com/ssps)!

## 2.0.0

- Dropping support for Chef 12

## 1.0.0 (BREAKING CHANGES!!)

- Refactor and update the legacy code base. Recipes are no longer provided, and custom resources are used to manage pyenv installations instead.
- update `system_install` to be a resource
- update `user_install` to be a resource
- update `script` resource
- update `python` resource
- update `global` resource
- update `rehash` resource
- create `plugin` resource
- create `pip` resource
- update integration tests
- add linting to CI
- delete all recipes
- delete matchers
- delete `chef_pyenv_recipe_helpers` library
- delete `chef_pyenv_mixin` library
- add support for Fedora, RedHat distros and OpenSUSE

## 0.2.0

- Add oracle linux support
- Update syntax for chef-client v13
- Update gems and dependencies
- Add integration tests on travis

## 0.1.4

- Updated deprecated methods used in attributes.rb

## 0.1.0

- Update default pyenv version to v0.4.0-20140516
- Add support for CentOS 6.5
- Install `make`, `build-essential`, `libssl-dev`, `zlib1g-dev`, `wget`,
  `curl`, and `llvm` on Debian machines

## 0.0.1

- Initial port of [chef-rbenv](https://github.com/fnichol/chef-rbenv)

[supported-versions]: https://docs.chef.io/platforms.html#supported-versions
