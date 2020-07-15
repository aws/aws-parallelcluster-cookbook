# yum Cookbook

[![Build Status](https://travis-ci.org/chef-cookbooks/yum.svg?branch=master)](http://travis-ci.org/chef-cookbooks/yum) [![Cookbook Version](https://img.shields.io/cookbook/v/yum.svg)](https://supermarket.chef.io/cookbooks/yum)

The Yum cookbook exposes the `yum_globalconfig` resource which allows a user to control global yum behavior. This resources aims to allow the user to configure all options listed in the `yum.conf` man page, found at <http://linux.die.net/man/5/yum.conf>

## Requirements

### Platforms

- RHEL/CentOS and derivatives
- Fedora

### Chef

- Chef 12.14+

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

## Recipes

- `default` - Configures `yum_globalconfig[/etc/yum.conf]` with values found in node attributes at `node['yum']['main']`
- `dnf_yum_compat` - Installs the yum package using dnf on Fedora systems to provide support for the package resource in recipes. This is necessary on chef-client < 12.18\. This recipe should be 1st on a Fedora runlist

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

## License & Authors

- Author:: Eric G. Wolfe
- Author:: Matt Ray ([matt@chef.io](mailto:matt@chef.io))
- Author:: Joshua Timberman ([joshua@chef.io](mailto:joshua@chef.io))
- Author:: Sean OMeara ([someara@chef.io](mailto:someara@chef.io))

```text
Copyright:: 2011 Eric G. Wolfe
Copyright:: 2013-2017 Chef Software, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
