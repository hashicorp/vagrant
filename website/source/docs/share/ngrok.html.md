---
layout: "docs"
page_title: "ngrok - Vagrant Share"
sidebar_current: "share-ngrok"
description: |-
  Vagrant share can be driven using ngrok for the underlying transport
  by supplying the "--driver ngrok" flag to "vagrant share".
---

# Sharing via ngrok

[ngrok](https://ngrok.com) is a hosted reverse proxy service. It allows you to
create a secure tunnel from a public endpoint to a locally running web service.

Vagrant share can be driven using ngrok from the underlying transport
by supplying the `--driver ngrok` flag to `vagrant share`.

The ngrok driver is not enabled by default. When starting the Vagrant
share, ngrok must be specified as the driver. Users connecting to
the share must also specify the ngrok driver to make a proper connection.


## Sharing

Starting a Vagrant share using the ngrok driver is very similar to the
default Vagrant share command. The only addition it requires is the
`--driver ngrok` flag:

```
$ vagrant share --driver ngrok
```

By default this will create a public HTTP endpoint
connected to the shared VM via an ngrok process. When only HTTP is being
shared, no connection is required from the remote side. All that is required
is the public ngrok URL.

### SSH

To share an ssh connection to the shared VM the `--ssh` flag must be provided.
Vagrant share will then create a small utility VM to enable the share with
remote users. Once the setup is complete, a name will be assigned to the
utility VM that remote users can reach using the `vagrant connect` command.

### Full Share

To enable full remote access to the shared VM the `--full` flag must be provided.
This will enable remote users connecting to the local share full access to all
forwarded ports defined by the shared VM Vagrantfile.

## Connecting

Much like the `vagrant share` command, when connecting to a Vagrant share
that was created using the ngrok driver, the `--driver ngrok` flag must
be provided:

```
$ vagrant connect --driver ngrok share_name
```

## ngrok configuration

The current user's ngrok configuration file is used by default when
tunnels are created for Vagrant share. While specific customization
to the ngrok configuration is not yet supported, the feature is being
actively worked on and will be available in the future.
