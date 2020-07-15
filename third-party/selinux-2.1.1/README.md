# SELinux Cookbook

[![Build Status](https://travis-ci.org/chef-cookbooks/selinux.svg?branch=master)](https://travis-ci.org/chef-cookbooks/selinux) [![Cookbook Version](https://img.shields.io/cookbook/v/selinux.svg)](https://supermarket.chef.io/cookbooks/selinux)

The SELinux (Security Enhanced Linux) cookbook provides recipes for manipulating SELinux policy enforcement state.

SELinux can have one of 3 settings

* Enforcing
 * Watches all system access checks, stops all 'Denied access'
 * Default mode on RHEL systems
* Permissive
 * Allows access but reports violations
* Disabled
 * Disables SELinux from the system but is only read at boot time. If you set this flag, you must reboot.

Disable SELinux only if you plan to not use it. Use `Permissive` mode if you just need to debug your system.

## Requirements

- Chef 12.7 or higher


## Platform:

The following platforms have been tested with Test Kitchen:

centos-6
centos-7

**NOTE** Support for debian and ubuntu is deprecated. It will be removed with the next release. The behavior on debian and rhel family operating systems is different as of 2.0.0. On debian and ubuntu systems if you want to enable SELinux you will need to do a few extra steps. As these are potentially destructive, rather than adding them to this cookbook adding this information here:

* _selinux-activate_ - Running `selinux-activate` will add parameters to the kernel, update grub configuration files, and set the file system to relabel upon reboot
* _reboot_ for settings to take effect.

## Usage


## Attributes


* `node['selinux']['booleans']` - A hash of SELinux boolean names and the
  values they should be set to. Values can be off, false, or 0 to disable;
  or on, true, or 1 to enable.

## Resources Overview


### selinux\_state

The `selinux_state` resource is used to manage the SELinux state on the
system. It does this by using the `setenforce` command and rendering
the `/etc/selinux/config` file from a template.

#### Actions

* `:nothing` - default action, does nothing
* `:enforcing` - Sets SELinux to enforcing.
* `:disabled` - Sets SELinux to disabled.
* `:permissive` - Sets SELinux to permissive.

#### Attributes

* `temporary` - true, false, default false. Allows the temporary change between permisive and enabled states which don't require a reboot. 
* `selinuxtype` - targeted, mls, default targeted. Determines the policy that will be configured in the `/etc/selinux/config` file. The default value is `targeted` which enables selinux in a mode where only selected processes are protected. `mls` is multilevel security which enables selinux in a mode where all processes are protected.

#### Examples

Simply set SELinux to enforcing or permissive:

    selinux_state "SELinux Enforcing" do
      action :enforcing
    end

    selinux_state "SELinux Permissive" do
      action :permissive
    end

The action here is based on the value of the
`node['selinux']['status']` attribute, which we convert to lower-case
and make a symbol to pass to the action.

    selinux_state "SELinux #{node['selinux']['status'].capitalize}" do
      action node['selinux']['status'].downcase.to_sym
    end

### selinux\_install

The `selinux_install` resource is used to encapsulate the set of selinux packages to install in order to manage selinux. It also ensures the directory `/etc/selinux` is created.

Recipes
=======

All recipes will deprecate in the near future as they are just using the `selinux_state` resource.

## default

The default recipe will use the attribute `node['selinux']['status']`
in the `selinux_state` LWRP's action. By default, this will be `:enforcing`.

## enforcing

This recipe will use `:enforcing` as the `selinux_state` action.

## permissive

This recipe will use `:permissive` as the `selinux_state` action.

## disabled

This recipe will use `:disabled` as the `selinux_state` action.

Usage
=====

By default, this cookbook will have SELinux enforcing by default, as
the default recipe uses the `node['selinux']['status']` attribute,
which is "enforcing." This is in line with the policy of enforcing by
default on RHEL family distributions.

You can simply set the attribute in a role applied to the node:

    name "base"
    description "Base role applied to all nodes."
    default_attributes(
      "selinux" => {
        "status" => "permissive"
      }
    )

Or, you can apply the recipe to the run list (e.g., in a role):

    name "base"
    description "Base role applied to all nodes."
    run_list(
      "recipe[selinux::permissive]",
    )


## License & Authors

* **Author:** Sean OMeara ([sean@sean.io](mailto:sean@sean.io))
* **Author:** Joshua Timberman ([joshua@chef.io](mailto:joshua@chef.io))
* **Author:** Jennifer Davis ([sigje@chef.io](mailto:sigje@chef.io))

**Copyright:** 2008-2017, Chef Software, Inc.

```
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
