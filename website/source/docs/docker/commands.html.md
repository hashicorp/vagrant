---
layout: "docs"
page_title: "Commands - Docker Provider"
sidebar_current: "providers-docker-commands"
description: |-
  The Docker provider exposes some additional Vagrant commands that are
  useful for interacting with Docker containers. This helps with your
  workflow on top of Vagrant so that you have full access to Docker
  underneath.
---

# Docker Commands

The Docker provider exposes some additional Vagrant commands that are
useful for interacting with Docker containers. This helps with your
workflow on top of Vagrant so that you have full access to Docker
underneath.

### docker-exec

`vagrant docker-exec` can be used to run one-off commands against
a Docker container that is currently running. If the container is not running,
an error will be returned.

```sh
$ vagrant docker-exec app -- rake db:migrate
```

The above would run `rake db:migrate` in the context of an `app` container.

Note that the "name" corresponds to the name of the VM, **not** the name of the
Docker container. Consider the following Vagrantfile:

```ruby
Vagrant.configure(2) do |config|
  config.vm.provider "docker" do |d|
    d.image = "consul"
  end
end
```

This Vagrantfile will start the official Docker Consul image. However, the
associated Vagrant command to `docker-exec` into this instance is:

```sh
$ vagrant docker-exec -it -- /bin/sh
```

In particular, the command is actually:

```sh
$ vagrant docker-exec default -it -- /bin/sh
```

Because "default" is the default name of the first defined VM. In a
multi-machine Vagrant setup as shown below, the "name" attribute corresponds
to the name of the VM, **not** the name of the container:

```ruby
Vagrant.configure do |config|
  config.vm.define "web" do
    config.vm.provider "docker" do |d|
      d.image = "nginx"
    end
  end

  config.vm.define "consul" do
    config.vm.provider "docker" do |d|
      d.image = "consul"
    end
  end
end
```

The following command is invalid:

```sh
# Not valid
$ vagrant docker-exec -it nginx -- /bin/sh
```

This is because the "name" of the VM is "web", so the command is actually:

```sh
$ vagrant docker-exec -it web -- /bin/sh
```

For this reason, it is recommended that you name the VM the same as the
container. In the above example, it is unambiguous that the command to enter
the Consul container is:

```sh
$ vagrant docker-exec -it consul -- /bin/sh
```

### docker-logs

`vagrant docker-logs` can be used to see the logs of a running container.
Because most Docker containers are single-process, this is used to see
the logs of that one process. Additionally, the logs can be tailed.

### docker-run

`vagrant docker-run` can be used to run one-off commands against
a Docker container. The one-off Docker container that is started shares
all the volumes, links, etc. of the original Docker container. An
example is shown below:

```sh
$ vagrant docker-run app -- rake db:migrate
```

The above would run `rake db:migrate` in the context of an `app` container.
