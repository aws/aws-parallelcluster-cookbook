# yum Cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/yum.svg)](https://supermarket.chef.io/cookbooks/yum)
[![CI State](https://github.com/sous-chefs/yum/workflows/ci/badge.svg)](https://github.com/sous-chefs/yum/actions?query=workflow%3Aci)
[![OpenCollective](https://opencollective.com/sous-chefs/backers/badge.svg)](#backers)
[![OpenCollective](https://opencollective.com/sous-chefs/sponsors/badge.svg)](#sponsors)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

The Yum cookbook exposes the `yum_globalconfig` resource which allows a user to control global yum behavior. This resources aims to allow the user to configure all options listed in the `yum.conf` man page, found at <http://man7.org/linux/man-pages/man5/yum.conf.5.html>

## Maintainers

This cookbook is maintained by the Sous Chefs. The Sous Chefs are a community of Chef cookbook maintainers working together to maintain important cookbooks. If you’d like to know more please visit [sous-chefs.org](https://sous-chefs.org/) or come chat with us on the Chef Community Slack in [#sous-chefs](https://chefcommunity.slack.com/messages/C2V7B88SF).

## Requirements

### Platforms

- AlmaLinux
- Amazon Linux 2023
- CentOS Stream
- Fedora
- Oracle Linux
- Red Hat Enterprise Linux
- Rocky Linux

### Chef

- Chef 15.3+

### Cookbooks

- none

## Resources

- [`yum_globalconfig`](documentation/yum_globalconfig.md)
- [`dnf_module`](documentation/dnf_module.md)

## Migration

This cookbook has completed a full custom resource migration. Recipes and node
attributes were removed in favor of resource properties. See
[migration.md](migration.md) for the breaking-change migration path.

## Related Cookbooks

Recipes from older versions of this cookbook have been moved individual cookbooks. Recipes for managing platform yum configurations and installing specific repositories can be found in one (or more!) of the following cookbook.

- yum-centos
- yum-fedora
- yum-amazon
- yum-epel
- yum-elrepo
- yum-repoforge
- yum-ius
- yum-percona
- yum-pgdg

## Usage

Put `depends 'yum'` in your metadata.rb to gain access to the resources.

```ruby
yum_globalconfig '/etc/yum.conf' do
  action :create
end
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
