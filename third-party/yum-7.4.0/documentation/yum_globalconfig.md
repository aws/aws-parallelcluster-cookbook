[Back to resource list](../README.md#Resources)

# `yum_globalconfig`

This renders a template with global yum configuration parameters. The default recipe uses it to render `/etc/yum.conf`. It is flexible enough to be used in other scenarios, such as building RPMs in isolation by modifying `installroot`.

## Properties

`yum_globalconfig` can take most of the same parameters as a `yum_repository`, plus more, too numerous to describe here. Below are a few of the more commonly used ones. For a complete list, please consult the [`yum.conf` man page](http://linux.die.net/man/5/yum.conf)

- `cachedir` - Directory where yum should store its cache and db files. The default is '/var/cache/yum'.
- `keepcache` - Either `true` or `false`. Determines whether or not yum keeps the cache of headers and packages after successful installation. Default is `false`
- `debuglevel` - Debug message output level. Practical range is 0-10\. Default is '2'.
- `exclude` - List of packages to exclude from updates or installs. This should be a space separated list. Shell globs using wildcards (eg. * and ?) are allowed.
- `install_weak_deps` - Either `true` or `false`. When this option is set to true and a new package is about to be installed, all packages linked by a weak dependency relation (i.e., Recommends or Supplements flags) with this package will be pulled into the transaction. Unspecified by default; DNF's default is true.
- `installonlypkgs` = List of package provides that should only ever be installed, never updated. Kernels in particular fall into this category. Defaults to kernel, kernel-bigmem, kernel-enterprise, kernel-smp, kernel-debug, kernel-unsupported, kernel-source, kernel-devel, kernel-PAE, kernel-PAE-debug.
- `logfile` - Full directory and file name for where yum should write its log file.
- `exactarch` - Either `true` or `false`. Set to `true` to make 'yum update' only update the architectures of packages that you have installed. ie: with this enabled yum will not install an i686 package to update an x86_64 package. Default is `true`
- `gpgcheck` - Either `true` or `false`. This tells yum whether or not it should perform a GPG signature check on the packages gotten from this repository.

## Example

```ruby
yum_globalconfig '/my/chroot/etc/yum.conf' do
  cachedir '/my/chroot/etc/yum.conf'
  keepcache 'yes'
  debuglevel '2'
  installroot '/my/chroot'
  action :create
end
```
