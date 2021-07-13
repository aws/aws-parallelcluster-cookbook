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

- RHEL/CentOS and derivatives
- Fedora

### Chef

- Chef 13+

### Cookbooks

- none

## Resources

### yum_globalconfig

This renders a template with global yum configuration parameters. The default recipe uses it to render `/etc/yum.conf`. It is flexible enough to be used in other scenarios, such as building RPMs in isolation by modifying `installroot`.

#### Example

```ruby
yum_globalconfig '/my/chroot/etc/yum.conf' do
  cachedir '/my/chroot/etc/yum.conf'
  keepcache 'yes'
  debuglevel '2'
  installroot '/my/chroot'
  action :create
end
```

#### Properties

`yum_globalconfig` can take most of the same parameters as a `yum_repository`, plus more, too numerous to describe here. Below are a few of the more commonly used ones. For a complete list, please consult the `yum.conf` man page, found here: <http://linux.die.net/man/5/yum.conf>

- `cachedir` - Directory where yum should store its cache and db files. The default is '/var/cache/yum'.
- `keepcache` - Either `true` or `false`. Determines whether or not yum keeps the cache of headers and packages after successful installation. Default is `false`
- `debuglevel` - Debug message output level. Practical range is 0-10\. Default is '2'.
- `exclude` - List of packages to exclude from updates or installs. This should be a space separated list. Shell globs using wildcards (eg. * and ?) are allowed.
- `installonlypkgs` = List of package provides that should only ever be installed, never updated. Kernels in particular fall into this category. Defaults to kernel, kernel-bigmem, kernel-enterprise, kernel-smp, kernel-debug, kernel-unsupported, kernel-source, kernel-devel, kernel-PAE, kernel-PAE-debug.
- `logfile` - Full directory and file name for where yum should write its log file.
- `exactarch` - Either `true` or `false`. Set to `true` to make 'yum update' only update the architectures of packages that you have installed. ie: with this enabled yum will not install an i686 package to update an x86_64 package. Default is `true`
- `gpgcheck` - Either `true` or `false`. This tells yum whether or not it should perform a GPG signature check on the packages gotten from this repository.

### yum_repository

This resource is now provided by chef-client 12.14 and later and has been removed from this cookbook. If you require this resource we highly recommend upgrading your chef-client, but if that is not an option you can pin the 4.X yum cookbook.

## Recipes (deprecated)

- `default` - Configures `yum_globalconfig[/etc/yum.conf]` with values found in node attributes at `node['yum']['main']`

## Attributes

The following attributes are set by default

```ruby
default['yum']['main']['cachedir'] = '/var/cache/yum/$basearch/$releasever'
default['yum']['main']['keepcache'] = false
default['yum']['main']['debuglevel'] = nil
default['yum']['main']['exclude'] = nil
default['yum']['main']['logfile'] = '/var/log/yum.log'
default['yum']['main']['exactarch'] = nil
default['yum']['main']['obsoletes'] = nil
default['yum']['main']['installonly_limit'] = nil
default['yum']['main']['installonlypkgs'] = nil
default['yum']['main']['installroot'] = nil
```

For Amazon platform nodes, the default is to receive a continuous flow of updates,

```ruby
default['yum']['main']['releasever'] = 'latest'
```

To lock existing instances to the current version of the Amazon AMI,

```ruby
default['yum']['main']['releasever'] = ''
```

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

Put `depends 'yum'` in your metadata.rb to gain access to the yum_repository resource.

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
