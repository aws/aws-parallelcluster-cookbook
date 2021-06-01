# yum-epel Cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/yum-epel.svg)](https://supermarket.chef.io/cookbooks/yum-epel)
[![CI State](https://github.com/sous-chefs/yum-epel/workflows/ci/badge.svg)](https://github.com/sous-chefs/yum-epel/actions?query=workflow%3Aci)
[![OpenCollective](https://opencollective.com/sous-chefs/backers/badge.svg)](#backers)
[![OpenCollective](https://opencollective.com/sous-chefs/sponsors/badge.svg)](#sponsors)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

Extra Packages for Enterprise Linux (or EPEL) is a Fedora Special Interest Group that creates, maintains, and manages a high quality set of additional packages for Enterprise Linux, including, but not limited to, Red Hat Enterprise Linux (RHEL), CentOS and Scientific Linux (SL), Oracle Linux (OL).

The yum-epel cookbook takes over management of the default repositoryids shipped with epel-release.

Below is a table showing which repositoryids we manage that are shipped by default via the epel-release package:

| Repo ID                        | EL 7             | EL 8             |
| ------------------------------ | :--------------: | :--------------: |
| epel                           |:heavy_check_mark:|:heavy_check_mark:|
| epel-debuginfo                 |:heavy_check_mark:|:heavy_check_mark:|
| epel-modular                   |       :x:        |:heavy_check_mark:|
| epel-modular-debuginfo         |       :x:        |:heavy_check_mark:|
| epel-modular-source            |       :x:        |:heavy_check_mark:|
| epel-playground                |       :x:        |:heavy_check_mark:|
| epel-playground-debuginfo      |       :x:        |:heavy_check_mark:|
| epel-playground-source         |       :x:        |:heavy_check_mark:|
| epel-source                    |:heavy_check_mark:|:heavy_check_mark:|
| epel-testing                   |:heavy_check_mark:|:heavy_check_mark:|
| epel-testing-debuginfo         |:heavy_check_mark:|:heavy_check_mark:|
| epel-testing-modular           |       :x:        |:heavy_check_mark:|
| epel-testing-modular-debuginfo |       :x:        |:heavy_check_mark:|
| epel-testing-modular-source    |       :x:        |:heavy_check_mark:|
| epel-testing-source            |:heavy_check_mark:|:heavy_check_mark:|

## Requirements

### Platforms

- RHEL/CentOS and derivatives

### Chef

- Chef 12.15+

## Maintainers

This cookbook is maintained by the Sous Chefs. The Sous Chefs are a community of Chef cookbook maintainers working together to maintain important cookbooks. If you’d like to know more please visit [sous-chefs.org](https://sous-chefs.org/) or come chat with us on the Chef Community Slack in [#sous-chefs](https://chefcommunity.slack.com/messages/C2V7B88SF).

### Cookbooks

- none

## Attributes

See individual repository attribute files for defaults.

## Recipes

- `yum-epel::default` Generates `yum_repository` configs for the standard EPEL repositories. By default the `epel` repository is enabled.

## Usage Example

To disable the epel repository through a Role or Environment definition

```
default_attributes(
  :yum => {
    :epel => {
      :enabled => {
        false
       }
     }
   }
 )
```

Uncommonly used repositoryids are not managed by default. This is speeds up integration testing pipelines by avoiding yum-cache builds that nobody cares about. To enable the epel-testing repository with a wrapper cookbook, place the following in a recipe:

```ruby
node.default['yum']['epel-testing']['enabled'] = true
node.default['yum']['epel-testing']['managed'] = true
include_recipe 'yum-epel'
```

## More Examples

Point the epel repositories at an internally hosted server.

```ruby
node.default['yum']['epel']['enabled'] = true
node.default['yum']['epel']['mirrorlist'] = nil
node.default['yum']['epel']['baseurl'] = 'https://internal.example.com/centos/7/os/x86_64'
node.default['yum']['epel']['sslverify'] = false

include_recipe 'yum-epel'
```

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
