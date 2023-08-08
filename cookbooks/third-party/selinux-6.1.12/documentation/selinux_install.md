[Back to resource list](../README.md#resources)

# selinux_install

The `selinux_install` resource is used to encapsulate the set of selinux packages to install in order to manage selinux. It also ensures the directory `/etc/selinux` is created.

Introduced: v4.0.0

## Actions

| Action     | Description                           |
| ---------- | ------------------------------------- |
| `:install` | *(Default)* Install required packages |
| `:upgrade` | Upgrade required packages             |
| `:remove`  | Remove any SELinux-related packages   |

## Properties

| Name       | Type          | Default                                                   | Description                 |
| ---------- | ------------- | --------------------------------------------------------- | --------------------------- |
| `packages` | String, Array | see [`default_install_packages`](../libraries/install.rb) | SELinux packages for system |

## Examples

### Default installation

```ruby
selinux_install 'example'
```

### Install with custom packages

```ruby
selinux_install 'example' do
  packages %w(policycoreutils selinux-policy selinux-policy-targeted)
end
```

### Uninstall

```ruby
selinux_install 'example' do
  action :remove
end
```
