[Back to resource list](../README.md#Resources)

# `dnf_module`

Provides interactions with the `dnf module` commands.

## Actions

These map to `dnf module` subcommands, documented [here](https://dnf.readthedocs.io/en/latest/command_ref.html#module-command) A basic summary for each is included below:

- `:switch_to` - *(Default)* Enable a module stream and upgrade any packages to versions provided by the module
- `:enable` - Enable a module stream without installing any packages
- `:disable` - Disable a module stream without removing any packages
- `:install` - Enable a module stream and install its packages
- `:remove` - Disable a module stream and remove its packages
- `:reset` - Unset module state and remove packages not in the default streams **(this action is not idempotent)**

## Properties

| Name          | Type                | Default       | Description                                                     |
| ------------- | ------------------- | ------------- | --------------------------------------------------------------- |
| `module_name` | `String`            | Resource name | Name of the module to install.                                  |
| `options`     | `String` or `Array` |               | Any additional options to pass to DNF                           |
| `flush_cache` | `true`, `false`     | `true`        | Whether to flush the Chef package cache after the module action |

Flushing Chef's package cache is needed when switching to a module stream added *during* the Chef run, e.g. from a new repo.

## Examples

Enable or update the Postgres module and related installed packages to PG 13:

```rb
# this is the default action
dnf_module 'postgres:13' do
  action :switch_to
end
```

Enable the Ruby 2.7 module (but do not install any of the packages):

```rb
dnf_module 'ruby:2.7' do
  action :enable
end
```

Enable and install packages from the PHP 7.4 module:

```rb
dnf_module 'php:7.4' do
  action :install
end
```
