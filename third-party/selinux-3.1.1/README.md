# SELinux Cookbook

[![Build Status](https://travis-ci.org/chef-cookbooks/selinux.svg?branch=master)](https://travis-ci.org/chef-cookbooks/selinux) [![Cookbook Version](https://img.shields.io/cookbook/v/selinux.svg)](https://supermarket.chef.io/cookbooks/selinux)

The SELinux (Security Enhanced Linux) cookbook provides recipes for manipulating SELinux policy enforcement state.

SELinux can have one of three settings:

`Enforcing`

- Watches all system access checks, stops all 'Denied access'
- Default mode on RHEL systems

`Permissive`

- Allows access but reports violations

`Disabled`

- Disables SELinux from the system but is only read at boot time. If you set this flag, you must reboot.

Disable SELinux only if you plan to not use it. Use `Permissive` mode if you just need to debug your system.

## Requirements

- Chef 13 or higher

## Platform:

- RHEL 6/7

## Attributes

- `node['selinux']['state']` - The SELinux policy enforcement state. The state to set by default, to match the default SELinux state on RHEL. Can be "enforcing", "permissive", "disabled"
- `node['selinux']['booleans']` - A hash of SELinux boolean names and the values they should be set to. Values can be off, false, or 0 to disable; or on, true, or 1 to enable.
- `node['selinux']['install_mcstrans_package']` - Install mcstrans package, Default is `true`. If don't want to install mcstrans package, sets as a `false`

## Resources Overview

### selinux_state

The `selinux_state` resource is used to manage the SELinux state on the system. It does this by using the `setenforce` command and rendering the `/etc/selinux/config` file from a template.

## selinux_module

This provider is intended to be part of the SELinux analysis workflow using tools like `audit2allow`.

### Actions

- `:create`: install the module;
- `:remove`: remove the module;

### Options

- `source`: SELinux `.te` file, to be parsed, compiled and deployed as module. If simple basename informed, the provider will first look into `files/default/selinux` directory;
- `base_dir`: Base directory to create and manage SELinux files, by default is `/etc/selinux/local`;
- `force`: Boolean. Indicates if provider should re-install the same version of SELinux module already installed, in case the source `.te` file changes;

### Attributes

LWRP interface, recipe attributes are not applicable here.

## selinux_state

The `selinux_state` resource is used to manage the SELinux state on the system. It does this by using the `setenforce` command and rendering the `/etc/selinux/config` file from a template.

### Actions

- `:nothing`: default action, does nothing
- `:enforcing`: Sets SELinux to enforcing.
- `:disabled`: Sets SELinux to disabled.
- `:permissive`: Sets SELinux to permissive.

### Properties

- `temporary` - true, false, default false. Allows the temporary change between permissive and enabled states which don't require a reboot.
- `selinuxtype` - targeted, mls, default targeted. Determines the policy that will be configured in the `/etc/selinux/config` file. The default value is `targeted` which enables selinux in a mode where only selected processes are protected. `mls` is multilevel security which enables selinux in a mode where all processes are protected.

### Examples

#### Managing SELinux State (`selinux_state`)

Simply set SELinux to enforcing or permissive:

```ruby
selinux_state "SELinux Enforcing" do
  action :enforcing
end

selinux_state "SELinux Permissive" do
  action :permissive
end
```

The action here is based on the value of the `node['selinux']['state']` attribute, which we convert to lower-case and make a symbol to pass to the action.

```ruby
selinux_state "SELinux #{node['selinux']['state'].capitalize}" do
  action node['selinux']['state'].downcase.to_sym
end
```

The action here is based on the value of the `node['selinux']['status']` attribute, which we convert to lower-case and make a symbol to pass to the action.

```ruby
selinux_state "SELinux #{node['selinux']['status'].capitalize}" do
  action node['selinux']['status'].downcase.to_sym
end
```

#### Managing SELinux Modules (`selinux_module`)

Consider the following steps to obtain a `.te` file, the rule description format employed on SELinux

1. Add `selinux` to your `metadata.rb`, as for instance: `depends 'selinux', '>= 0.10.0'`;
2. Run your SELinux workflow, and add `.te` files on your cookbook files, preferably under `files/default/selinux` directory;
3. Write recipes using `selinux_module` provider;

#### SELinux `audit2allow` Workflow

This provider was written with the intention of matching the workflow of `audit2allow` (provided by package `policycoreutils`), which basically will be:

1. Test application and inspect `/var/log/audit/audit.log` log-file with a command like this basic example: `grep AVC /var/log/audit/audit.log |audit2allow -M my_application`;
2. Save `my_application.te` SELinux module source, copy into your cookbook under `files/default/selinux/my_application.te`;
3. Make use of `selinux` provider on a recipe, after adding it as a dependency;

For example, add the following on the recipe level:

```ruby
selinux_module 'MyApplication SELinux Module' do
  source 'my_application.te'
  action :create
end
```

Module name is defined on `my_application.te` file contents, please note this input, is used during `:remove` action. For instance:

```ruby
selinux_module 'my_application' do
  action :remove
end
```

### selinux_install

The `selinux_install` resource is used to encapsulate the set of selinux packages to install in order to manage selinux. It also ensures the directory `/etc/selinux` is created.

## Recipes

All recipes will deprecate in the near future as they are just using the `selinux_state` resource.

### default

The default recipe will use the attribute `node['selinux']['status']` in the `selinux_state` resource's action. By default, this will be `:enforcing`.

### enforcing

This recipe will use `:enforcing` as the `selinux_state` action.

### permissive

This recipe will use `:permissive` as the `selinux_state` action.

### disabled

This recipe will use `:disabled` as the `selinux_state` action.

## Usage

By default, this cookbook will have SELinux enforcing by default, as the default recipe uses the `node['selinux']['status']` attribute, which is "enforcing." This is in line with the policy of enforcing by default on RHEL family distributions.

You can simply set the attribute in a role applied to the node:

```
name "base"
description "Base role applied to all nodes."
default_attributes(
  "selinux" => {
    "status" => "permissive"
  }
)
```

Or, you can apply the recipe to the run list (e.g., in a role):

```
name "base"
description "Base role applied to all nodes."
run_list(
  "recipe[selinux::permissive]",
)
```

## License & Authors

- **Author:** Sean OMeara ([sean@sean.io](mailto:sean@sean.io))
- **Author:** Joshua Timberman ([joshua@chef.io](mailto:joshua@chef.io))
- **Author:** Jennifer Davis ([sigje@chef.io](mailto:sigje@chef.io))

**Copyright:** 2008-2018, Chef Software, Inc.

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
