NFS
---

[![Build Status](https://secure.travis-ci.org/atomic-penguin/cookbook-nfs.png?branch=master)](http://travis-ci.org/atomic-penguin/cookbook-nfs)

Description
-----------

Installs and configures NFS client, or server components 

Requirements
------------

Should work on any RHEL, Debian, Ubuntu, SUSE, and FreeBSD distributions.

This cookbook depends on Sean O'Meara's [line cookbook](https://github.com/someara/line-cookbook)

### Attributes

* `nfs['packages']`
  - Case switch in attributes to choose NFS client packages dependent on platform.

* `nfs['service']`
  - `['portmap']` - the portmap or rpcbind service depending on platform
  - `['lock']` - the statd or nfslock service depending on platform
  - `['server']` - the server component, nfs or nfs-kernel-server depending on platform
  - `['idmap']` - the NFSv4 idmap component

* `nfs['service_provider']`
  - NOTE: This is a hack to set the service provider explicitly to Upstart on Ubuntu platforms.
  - `['portmap']` - provider for portmap service, chosen by platform
  - `['lock']` - provider for lock service, chosen by platform
  - `['server']` - provider for server service, chosen by platform
  - `['idmap']` - provider for NFSv4 idmap service

* `nfs['config']`
  - `client_templates` - templates to iterate through on client systems, chosen by platform
  - `server_template` - Per-platform case switch in common nfs.erb template.  This string should be
     set to where the main NFS server configuration file should be placed.
  - `idmap_template` - Path to idmapd.conf used in `nfs::client4` and `nfs::server4` recipes.

* `nfs['threads']` - Number of nfsd threads to run.  Default 8 on Linux, 24 on FreeBSD.  Set to 0, to disable.

* `nfs['port']`
  - `['statd']` = Listen port for statd, default 32765
  - `['statd_out']` = Outgoing port for statd, default 32766
  - `['mountd']` = Listen port for mountd, default 32767
  - `['lockd']` = Listen port for lockd, default 32768

* `nfs['v2']`, `nfs['v3']`, `nfs['v4']`
  - Set to `yes` or `no` to turn on/off NFS protocol level v2, or v3.
  - Defaults to nil, deferring to the default behavior provided by running kernel. 

* `nfs['mountd_flags']` - BSD launch options for mountd.
  `nfs['server_flags']` - BSD launch options for nfsd.

* `nfs['idmap']`
   - Attributes specific to idmap template and service.
   - `['domain']` - Domain for idmap service, defaults to `node['domain']`
   - `['pipefs_directory']` - platform-specific location of `Pipefs-Directory`
   - `['user']` - effective user for idmap service, default `nobody`.
   - `['group']` - effective group for idmap service, default `nogroup`.

## Usage

To install the NFS components for a client system, simply add nfs to the run\_list.

    name "base"
    description "Role applied to all systems"
    run_list [ "nfs" ]

Then in an `nfs_server.rb` role that is applied to NFS servers:

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

### `nfs_export` LWRP Usage

Applications or other cookbooks can use the nfs\_export LWRP to add exports:

    nfs_export "/exports" do
      network '10.0.0.0/8'
      writeable false 
      sync true
      options ['no_root_squash']
    end

The default parameters for the `nfs_export` LWRP are as follows

* directory 
  - directory you wish to export
  - defaults to resource name

* network
  - a CIDR, IP address, or wildcard (\*)
  - requires an option
  - can be a string for a single address or an array of networks

* writeable
  - ro/rw export option
  - defaults to false

* sync
  - synchronous/asynchronous export option
  - defaults to true

* anonuser
  - user mapping for anonymous users
  - the user's UID will be retrieved from /etc/passwd for the anonuid=x option
  - defaults to nil (no mapping)

* anongroup
  - group mapping for anonymous users
  - the group's GID will be retrieved from /etc/group for the anongid=x option
  - defaults to nil (no mapping)

* options
  - additional export options as an array, excluding the parameterized sync/async, ro/rw options, and anoymous mappings
  - defaults to `root_squash`

## nfs::default recipe

The default recipe installs and configures the common components for an NFS client, at an effective protocol level of
NFSv3.  The Chef resource logic for this is in the `nfs::_common` recipe, with platform-specific conditional defaults
set in the default attributes file.

## nfs::client4 recipe

Includes the logic from `nfs::_common`, and also configures and installs the idmap service to provide an effective protocol
level of NFSv4.  Effectively the same as running both `nfs::_common` and `nfs::_idmap`.

## nfs::server recipe

The server recipe includes the common client components from `nfs::_common`.  This also configures and installs the
platform-specific server services for an effective protocol level of NFSv3.

## nfs::server4 recipe

This recipe includes the common client components from `nfs::_common`.  It also configures and installs the
platform-specific server services for an effective protocol level of NFSv4.  Effectively the same as running
`nfs::_common` and `nfs::_idmap` and `nfs::server`.

## nfs::undo recipe

Does your freshly kickstarted/preseeded system come with NFS, when you didn't ask for NFS?  This recipe inspired by the
annoyances cookbook, will run once to remove NFS from the system.  Use a knife command to remove NFS components from your
system like so.

    knife run_list add <node name> nfs::undo

## License and Author

Author: Eric G. Wolfe (eric.wolfe@gmail.com) [![endorse](https://api.coderwall.com/atomic-penguin/endorsecount.png)](https://coderwall.com/atomic-penguin)
Contributors: Riot Games, Sean OMeara

Copyright 2011-2017, Eric G. Wolfe
Copyright 2014, Joe Rocklin
Copyright 2012, Riot Games
Copyright 2012, Sean OMeara

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
