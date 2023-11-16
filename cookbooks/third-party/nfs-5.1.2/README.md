# nfs cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/selnux.svg)](https://supermarket.chef.io/cookbooks/nfs)
[![CI State](https://github.com/sous-chefs/nfs/workflows/ci/badge.svg)](https://github.com/sous-chefs/nfs/actions?query=workflow%3Aci)
[![OpenCollective](https://opencollective.com/sous-chefs/backers/badge.svg)](#backers)
[![OpenCollective](https://opencollective.com/sous-chefs/sponsors/badge.svg)](#sponsors)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

## Description

Installs and configures NFS client and server components

## Maintainers

This cookbook is maintained by the Sous Chefs. The Sous Chefs are a community of Chef cookbook maintainers working together to maintain important cookbooks. If you’d like to know more please visit [sous-chefs.org](https://sous-chefs.org/) or come chat with us on the Chef Community Slack in [#sous-chefs](https://chefcommunity.slack.com/messages/C2V7B88SF).

## Requirements

Should work on any RHEL 7+, Debian 10+, Ubuntu 18.04+ distributions.

This cookbook depends on the [`line` cookbook](https://github.com/sous-chefs/line)

### Attributes

- `nfs['packages']`
   - Case switch in attributes to choose NFS client packages dependent on platform.

- `nfs['service']`
   - `['config']` - only set on Debian/Ubuntu to work around loose systemd dependencies on this platform family - debian:
    `nfs-config.service`
   - `['portmap']` - the rpcbind service - default: `nfs-client.target`
   - `['lock']` - the rpc-statd service - default: `nfs-client.target`, debian: `rpc-statd.service`
   - `['server']` - the server component, - default: `nfs-server.service`, debian: `nfs-kernel-server.service`
   - `['idmap']` - the NFSv4 idmap component

- `nfs['config']`
   - `client_templates` - templates to iterate through on client systems, chosen by platform
   - `server_template` - Per-platform case switch in common nfs.erb template. This string should be set to where the main
     NFS server configuration file should be placed.
   - `idmap_template` - Path to idmapd.conf used in `nfs::client4` and `nfs::server4` recipes.

- `nfs['threads']` - Number of nfsd threads to run. Default 8 on Linux, 24 on FreeBSD. Set to 0, to disable.

- `nfs['port']`
   - `['statd']` = Listen port for statd, default 32765
   - `['statd_out']` = Outgoing port for statd, default 32766
   - `['mountd']` = Listen port for mountd, default 32767
   - `['lockd']` = Listen port for lockd, default 32768

- `nfs['v2']`, `nfs['v3']`, `nfs['v4']`
   - Set to `yes` or `no` to turn on/off NFS protocol level v2, or v3.
   - Defaults to nil, deferring to the default behavior provided by running kernel.

- `nfs['mountd_flags']` - BSD launch options for mountd.
- `nfs['server_flags']` - BSD launch options for nfsd.

- `nfs['idmap']`
   - Attributes specific to idmap template and service.
   - `['domain']` - Domain for idmap service, defaults to `node['domain']`
   - `['pipefs_directory']` - platform-specific location of `Pipefs-Directory`
   - `['user']` - effective user for idmap service, default `nobody`.
   - `['group']` - effective group for idmap service, default `nogroup`.

## Usage

To install the NFS components for a client system, simply add nfs to the run list.

```ruby
name "base"
description "Role applied to all systems"
run_list [ "nfs" ]
```

Then in an `nfs_server.rb` role that is applied to NFS servers:

```ruby
name "nfs_server"
description "Role applied to the system that should be an NFS server."
override_attributes(
  "nfs" => {
    "packages" => [ "portmap", "nfs-common", "nfs-kernel-server" ],
    "port" => {
      "statd" => 32765,
      "statd_out" => 32766,
      "mountd" => 32767,
      "lockd" => 32768
    }
  }
)
run_list [ "nfs::server" ]
```

### `nfs_export` resource Usage

Applications or other cookbooks can use the `nfs_export` resource to add exports:

```ruby
nfs_export "/exports" do
  network '10.0.0.0/8'
  writeable false
  sync true
  options ['no_root_squash']
end
```

The default parameters for the `nfs_export` LWRP are as follows

- directory
   - directory you wish to export
   - defaults to resource name

- network
   - a CIDR, IP address, or wildcard (\*)
   - requires an option
   - can be a string for a single address or an array of networks

- writeable
   - ro/rw export option
   - defaults to false

- sync
   - synchronous/asynchronous export option
   - defaults to true

- anonuser
   - user mapping for anonymous users
   - the user's UID will be retrieved from /etc/passwd for the anonuid=x option
   - defaults to nil (no mapping)

- anongroup
   - group mapping for anonymous users
   - the group's GID will be retrieved from /etc/group for the anongid=x option
   - defaults to nil (no mapping)

- options
   - additional export options as an array, excluding the parameterized sync/async, ro/rw options, and anoymous mappings
   - defaults to `root_squash`

## nfs::default recipe

The default recipe installs and configures the common components for an NFS client, at an effective protocol level of
NFSv3. The Chef resource logic for this is in the `nfs::_common` recipe, with platform-specific conditional defaults set
in the default attributes file.

## nfs::client4 recipe

Includes the logic from `nfs::_common`, and also configures and installs the idmap service to provide an effective
protocol level of NFSv4. Effectively the same as running both `nfs::_common` and `nfs::_idmap`.

## nfs::server recipe

The server recipe includes the common client components from `nfs::_common`. This also configures and installs the
platform-specific server services for an effective protocol level of NFSv3.

## nfs::server4 recipe

This recipe includes the common client components from `nfs::_common`. It also configures and installs the
platform-specific server services for an effective protocol level of NFSv4. Effectively the same as running
`nfs::_common` and `nfs::_idmap` and `nfs::server`.

## nfs::undo recipe

Does your freshly kickstarted/preseeded system come with NFS, when you didn't ask for NFS?  This recipe inspired by the
annoyances cookbook, will run once to remove NFS from the system. Use a knife command to remove NFS components from your
system like so.

```sh
knife run_list add $NODE nfs::undo
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
