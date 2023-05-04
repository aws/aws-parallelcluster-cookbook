[Back to resource list](../README.md#resources)

# selinux_module

Create an SELinux module from a cookfile file or content provided as a string.

Introduced: v4.0.0

## Actions

| Action     | Description                                          |
| ---------- | ---------------------------------------------------- |
| `:create`  | *(Default)* Compile a module and install it          |
| `:delete`  | Remove module source files from `/etc/selinux/local` |
| `:install` | Install a compiled module into the system            |
| `:remove`  | Remove a module from the system                      |

## Properties

| Name          | Type   | Default              | Description                                     |
| ------------- | ------ | -------------------- | ----------------------------------------------- |
| `module_name` | String | Resource name        | Override the module name                        |
| `content`     | String |                      | Module source as text                           |
| `source`      | String |                      | Module source file name                         |
| `base_dir`    | String | `/etc/selinux/local` | Directory to create module source file in       |
| `cookbook`    | String |                      | Cookbook to source from module source file from |

## Examples

```ruby
selinux_module 'test_create' do
  cookbook 'selinux_test'
  source 'test.te'
  module_name 'test'
  action :install
end
```

```ruby
selinux_module 'test' do
  action :remove
end
```

## Usage

### Managing SELinux Modules (`selinux_module`)

Consider the following steps to obtain a `.te` file, the rule description format employed on SELinux

1. Add `selinux` to your `metadata.rb`, as for instance: `depends 'selinux', '>= 0.10.0'`;
2. Run your SELinux workflow, and add `.te` files on your cookbook files, preferably under `files/default/selinux` directory;
3. Write recipes using `selinux_module` resource;

### SELinux `audit2allow` Workflow

This resource was written with the intention of matching the workflow of `audit2allow` (provided by package `policycoreutils`), which basically will be:

1. Test application and inspect `/var/log/audit/audit.log` log-file with a command like this basic example: `grep AVC /var/log/audit/audit.log | audit2allow -M my_application`;
2. Save `my_application.te` SELinux module source, copy into your cookbook under `files/default/selinux/my_application.te`;
3. Make use of `selinux` resource on a recipe, after adding it as a dependency;

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
