# pyenv Chef Cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/pyenv.svg)](https://supermarket.chef.io/cookbooks/pyenv)
[![Build Status](https://img.shields.io/circleci/project/github/sous-chefs/pyenv/master.svg)](https://circleci.com/gh/sous-chefs/pyenv)
[![OpenCollective](https://opencollective.com/sous-chefs/backers/badge.svg)](#backers)
[![OpenCollective](https://opencollective.com/sous-chefs/sponsors/badge.svg)](#sponsors)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)
[![Maintainability](https://api.codeclimate.com/v1/badges/693934e931aa1c52bfa0/maintainability)](https://codeclimate.com/github/sous-chefs/pyenv/maintainability)

## Description

Manages [pyenv][pyenv] and its installed Pythons.

## Chef

This cookbook requires Chef 15.3+.

## Platform family

- Debian derivatives (debian, ubuntu)
- Fedora
- RHEL derivatives (RHEL, CentOS, Amazon Linux, Oracle, Scientific Linux)
- openSUSE and openSUSE leap

## Usage

Examples installations are provided in `test/fixtures/cookbooks/test/recipes`

A `pyenv_install` is required to be set so that pyenv knows which version you want to use, and is installed on the system.

## Resources

- [pyenv_global](documentation/pyenv_global.md)
- [pyenv_install](documentation/pyenv_install.md)
- [pyenv_pip](documentation/pyenv_pip.md)
- [pyenv_plugin](documentation/pyenv_plugin.md)
- [pyenv_python](documentation/pyenv_python.md)
- [pyenv_rehash](documentation/pyenv_rehash.md)
- [pyenv_script](documentation/pyenv_script.md)

## System-Wide Mac Installation Note

This cookbook takes advantage of managing profile fragments in an
`/etc/profile.d` directory, common on most Unix-flavored platforms.
Unfortunately, Mac OS X does not support this idiom out of the box,
so you may need to [modify][mac_profile_d] your user profile.

## Contributors

This project exists thanks to all the people who [contribute.](https://opencollective.com/sous-chefs/contributors.svg?width=890&button=false)

### Backers

Thank you to all our backers!

![https://opencollective.com/sous-chefs#backers](https://opencollective.com/sous-chefs/backers.svg?width=600&avatarHeight=40)

### Sponsors

Support this project by becoming a sponsor. Your logo will show up here with a link to your website.

![https://opencollective.com/sous-chefs/sponsor/0/website](https://opencollective.com/sous-chefs/sponsor/0/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/1/website](https://opencollective.com/sous-chefs/sponsor/1/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/2/website](https://opencollective.com/sous-chefs/sponsor/2/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/3/website](https://opencollective.com/sous-chefs/sponsor/3/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/4/website](https://opencollective.com/sous-chefs/sponsor/4/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/5/website](https://opencollective.com/sous-chefs/sponsor/5/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/6/website](https://opencollective.com/sous-chefs/sponsor/6/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/7/website](https://opencollective.com/sous-chefs/sponsor/7/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/8/website](https://opencollective.com/sous-chefs/sponsor/8/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/9/website](https://opencollective.com/sous-chefs/sponsor/9/avatar.svg?avatarHeight=100)

[pyenv]: https://github.com/pyenv/pyenv
