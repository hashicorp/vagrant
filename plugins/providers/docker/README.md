# docker-provider

[![Build Status](https://travis-ci.org/fgrehm/docker-provider.png?branch=master)](https://travis-ci.org/fgrehm/docker-provider) [![Gem Version](https://badge.fury.io/rb/docker-provider.png)](http://badge.fury.io/rb/docker-provider) [![Gittip](http://img.shields.io/gittip/fgrehm.svg)](https://www.gittip.com/fgrehm/)

A [Docker](http://www.docker.io/) provider for [Vagrant](http://www.vagrantup.com/)
1.4+.


## Warning

This is experimental, expect things to break.


## Requirements

* Vagrant 1.4+
* Docker 0.7.0+


## Features

* Support for Vagrant's `up`, `destroy`, `halt`, `reload` and `ssh` commands
* Port forwarding
* Synced / shared folders support
* Set container hostnames from Vagrantfiles
* Provision Docker containers with any built-in Vagrant provisioner (as long as the container has a SSH server running)

You can see the plugin in action by watching the following asciicasts I published
prior to releasing 0.0.1:

* http://asciinema.org/a/6162
* http://asciinema.org/a/6177


## Getting started

If you are on a Mac / Windows machine, please fire up a x64 Linux VM with Docker +
Vagrant 1.4+ installed or use [this Vagrantfile](https://gist.github.com/fgrehm/fc48fb51ec7df64439e4)
and follow the instructions from within the VM.

_It is likely that the plugin works with [boot2docker](http://boot2docker.github.io/)
but I personally haven't tried that yet. If you are able to give it a go please
[let me know](https://github.com/fgrehm/docker-provider/issues/new)._

### Initial setup

_If you are trying things out from a Vagrant VM using the `Vagrantfile` gisted
above, you can skip to the next section_

The plugin requires Docker's executable to be available on current user's `PATH`
and that the current user has been added to the `docker` group since we are not
using `sudo` when interacting with Docker's CLI. For more information on setting
this up please check [this page](http://docs.docker.io/en/latest/installation/ubuntulinux/#giving-non-root-access).

### `vagrant up`

On its current state, the plugin is not "user friendly" and won't provide any kind
of feedback about the process of downloading Docker images, so before you add a
`docker-provider` [base box](http://docs.vagrantup.com/v2/boxes.html) it is recommended
that you `docker pull` the associated base box images prior to spinning up `docker-provider`
containers (otherwise you'll be staring at a blinking cursor without any progress
information for a while).

Assuming you have Vagrant 1.4+ and Docker 0.7.0+ installed just sing that same
old song:

```sh
vagrant plugin install docker-provider
docker pull fgrehm/vagrant-ubuntu:precise
vagrant box add precise64 http://bit.ly/vagrant-docker-precise
vagrant init precise64
vagrant up --provider=docker
```

Under the hood, that base box will [configure](#configuration) `docker-provider`
to use the [`fgrehm/vagrant-ubuntu:precise`](https://index.docker.io/u/fgrehm/vagrant-ubuntu/)
image that approximates a standard Vagrant box (`vagrant` user, default SSH key,
etc.) and you should be good to go.


## Using custom images

If you want to use a custom Docker image without creating a Vagrant base box,
you can use a "dummy" box and configure things from your `Vagrantfile` like
in [vagrant-digitalocean](https://github.com/smdahlen/vagrant-digitalocean#configure)
or [vagrant-aws](https://github.com/mitchellh/vagrant-aws#quick-start):

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "dummy"
  config.vm.box_url = "http://bit.ly/vagrant-docker-dummy"
  config.vm.provider :docker do |docker|
    docker.image = "your/image:tag"
  end
end
```


## Configuration

This provider exposes a few provider-specific configuration options
that are passed on to `docker run` under the hood when the container
is being created:

* `image` - Docker image to run (required)
* `privileged` - Give extended privileges to the container (defaults to false)
* `cmd` - An array of strings that makes up for the command to run the container (defaults to what has been set on your `Dockerfile` as `CMD` or `ENTRYPOINT`)
* `ports` - An array of strings that makes up for the mapped network ports
* `volumes` - An array of strings that makes up for the data volumes used by the container

These can be set like typical provider-specific configuration:

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider :docker do |docker|
    docker.image      = 'fgrehm/vagrant-ubuntu-dind:precise'
    docker.privileged = true
    docker.cmd        = ['/dind', '/sbin/init']

    docker.ports   << '1234:22'
    docker.volumes << '/var/lib/docker'
  end
end
```


## Networks

Networking features in the form of `config.vm.network` are not supported with
`docker-provider` apart from [forwarded ports]().
If any of [`:private_network`](http://docs.vagrantup.com/v2/networking/private_network.html)
or [`:public_network`](http://docs.vagrantup.com/v2/networking/public_network.html)
are specified, Vagrant **won't** emit a warning.

The same applies to changes on forwarded ports after the container has been
created, Vagrant **won't** emit a warning to let you know that the ports specified
on your `Vagrantfile` differs from what has been passed on to `docker run` when
creating the container.

_At some point the plugin will emit warnings on the scenarios described above, but
not on its current state. Pull Requests are encouraged ;)_


## Synced Folders

There is support for synced folders on the form of [Docker volumes](http://docs.docker.io/en/latest/use/working_with_volumes/#mount-a-host-directory-as-a-container-volume)
but as with forwarded ports, you won't be able to change them after the container
has been created. [NFS](http://docs.vagrantup.com/v2/synced-folders/nfs.html)
synced folders are also supported (as long as you set the `privileged`
[config](#configuration) to true so that `docker-provider` can mount it on the
guest container) and are capable of being reconfigured between `vagrant reload`s
(different from Docker volumes).

This is good enough for all built-in Vagrant provisioners (shell,
chef, and puppet) to work!

_At some point the plugin will emit warnings when the configured `Vagrantfile`
synced folders / volumes differs from the ones used upon the container creation,
but not on its current state. Pull Requests are encouraged ;)_


## Box format

Every provider in Vagrant must introduce a custom box format. This provider introduces
`docker` boxes and you can view some examples in the [`boxes`](boxes) directory.
That directory also contains instructions on how to build them.

The box format is basically just the required `metadata.json` file along with a
`Vagrantfile` that does default settings for the provider-specific configuration
for this provider.


## Available base boxes

| LINK | DESCRIPTION |
| ---  | ---         |
| http://bit.ly/vagrant-docker-precise | Ubuntu 12.04 Precise x86_64 with Puppet and Chef preinstalled and configured to run `/sbin/init` |
| http://bit.ly/vagrant-docker-precise-dind | Ubuntu 12.04 Precise x86_64 based on the box above and ready to run [DinD](https://github.com/jpetazzo/dind) |


## Limitations

As explained on the [networks](#networks) and [synced folder](#synced-folders)
sections above, there are some "gotchas" when using the plugin that you need to have
in mind before you start to pull your hair out.

For instance, forwarded ports, synced folders and containers' hostnames will not be
reconfigured on `vagrant reload`s if they have changed and the plugin **_will not
give you any kind of warning or message_**. As an example, if you change your Puppet
manifests / Chef cookbooks paths (which are shared / synced folders under the hood),
**_you'll need to start from scratch_** (unless you make them NFS shared folders).
This is due to a limitation in Docker itself as we can't change those parameters
after the container has been created.

Forwarded ports automatic collision handling is **_not supported as well_**.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
