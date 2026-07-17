# Migration Guide

## Full Custom Resource Migration

The `yum` cookbook no longer provides public recipes or node attributes. Use the
custom resources directly from your wrapper cookbook recipes.

## Removed APIs

The following APIs were removed:

* `recipe[yum::default]`
* `node['yum']['main']` attributes

## Replacing `recipe[yum::default]`

Previously, the default recipe rendered `/etc/yum.conf` from
`node['yum']['main']` attributes:

```ruby
include_recipe 'yum::default'
```

Now declare the resource directly:

```ruby
yum_globalconfig '/etc/yum.conf' do
  action :create
end
```

## Replacing Attributes

Move values from `node['yum']['main']` to resource properties:

```ruby
yum_globalconfig '/etc/yum.conf' do
  cachedir '/var/cache/yum/$basearch/$releasever'
  debuglevel '2'
  exactarch true
  gpgcheck true
  installonly_limit '3'
  keepcache false
  logfile '/var/log/yum.log'
  plugins true
  action :create
end
```

Amazon Linux keeps the previous behavior by defaulting `releasever` to
`'latest'`. Set `releasever ''` to preserve the older AMI-locking behavior.

## Test Cookbook Examples

Example usage now lives in the test cookbook:

* `test/cookbooks/test/recipes/default.rb` renders `/etc/yum.conf`.
* `test/cookbooks/test/recipes/dnf_module.rb` exercises `dnf_module`.
* `test/cookbooks/test/recipes/test_globalconfig_two.rb` shows a heavily
  parameterized `yum_globalconfig` declaration.
