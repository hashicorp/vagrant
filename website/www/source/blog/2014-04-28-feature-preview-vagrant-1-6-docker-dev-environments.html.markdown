---
page_title: "Vagrant 1.6 Feature Preview: Docker-Based Development Environments"
title: "Feature Preview: Docker-Based Development Environments"
author: "Mitchell Hashimoto"
author_url: https://github.com/mitchellh
---

Vagrant 1.6 comes with a new built-in provider: Docker. The Docker provider
allows Vagrant to manage development environments that run within containers,
rather than virtual machines. This works without any additional software
required on Linux, Mac OS X, and Windows.

The Docker provider in Vagrant makes it incredibly easy to keep the workflow
you're used to with both Vagrant and Docker while gaining all the benefits
of Vagrant: cross-platform portability, synced folders, networking,
provisioners, vagrant share, plugins, etc.

On platforms that don't support Linux Containers natively such as
Mac OS X and Windows, Vagrant automatically brings up and shares a proxy
virtual machine to run Docker. This proxy VM is completely customizable,
and Vagrant ensures that synced folders and networking work as you would
expect. Users of Vagrant don't need to worry about doing any of
this manually.

Read on to learn more.

READMORE

### Demo

We've prepared a few demo videos below showcasing the Docker provider
in Vagrant before we get into the details in this blog post. We recommend
watching these videos in order.

<iframe src="//player.vimeo.com/video/93167741" width="680" height="382" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

<iframe src="//player.vimeo.com/video/93176926" width="680" height="382" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

<iframe src="//player.vimeo.com/video/93180496" width="680" height="382" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

### Docker, With Vagrant

Vagrant is built to be the best way to manage development environments
for applications built with any technology. In many cases, virtual machines
are the best answer for this, so Vagrant has used virtual machines for years.
But Vagrant isn't tied to virtual machines at all, and in some cases containers
are the best option. With the Docker provider, Vagrant builds development
environments with Linux containers built with Docker.

Users of Docker who use Vagrant for development get what Vagrant is best known
for: [the Vagrant workflow](http://mitchellh.com/the-tao-of-vagrant). One
`vagrant up` on Linux, Mac, or Windows and developers get a consistent
development environment that they can work on. No extra steps other than
installing Vagrant, no clicking, and no discontinuity between operating
systems.

And due to Vagrant's flexibility, you keep the identical workflow
for managing systems that don't use Docker. This might be another Linux-based
system, or it might even be something completely different such as a
[Windows-based development environment](/blog/feature-preview-vagrant-1-6-windows.html).
With Vagrant, the workflow is always the same.

### Docker Host VM

Linux containers do not run natively on non-Linux machines. If your developers
are on Mac or Windows, they can't run Docker containers natively. Vagrant
detects these cases and automatically spins up a Linux virtual machine to
run the Docker containers.

Vagrant then shares this virtual machine for all Docker-based development
environments with Vagrant. That means with just a single virtual machine,
Vagrant can manage many Docker environments.

Even when using a Docker host virtual machine, synced folders, SSH, and
other features of Vagrant work just as you expect, uniformly across every
platform.

If Vagrant is being used with Docker on Linux, Vagrant won't automatically
spin up a virtual machine and instead will run Docker natively.

By default, Vagrant spins up a default virtual machine with Docker installed.
But you can also specify **any Vagrant-managed machine** as the Docker
host machine. An example is shown below:

<pre class="prettyprint">
Vagrant.configure("2") do |config|
  config.vm.provider "docker" do |d|
    d.vagrant_vagrantfile = "../docker-host/Vagrantfile"
  end
end
</pre>

With the configuration above, Vagrant will use the default machine
in the Vagrantfile specified as the Docker host. This is _very powerful_.
With this feature, you can have Vagrant automatically manage a Docker
host using any operating system that Vagrant supports, such as Ubuntu,
RHEL, or CoreOS. And you can change this host VM for each development
environment if you want.

Vagrant is smart: if the host VM matches multiple Vagrantfiles, the single
VM will be shared. Vagrant won't spin up multiple VMs if it doesn't have to.

Because Vagrant is just re-using Vagrant underneath the covers to manage
this host VM, you're able to use all the features of Vagrant with this VM:
provisioners, synced folders, networking, etc. It is the ultimate flexibility
in building a development environment that is correct for your project.

### Dockerfiles or Docker Index

The Docker provider in Vagrant is flexible and supports Docker containers
from both local Dockerfiles and the Docker Index. This is useful in being
able to iterate on a Dockerfile while also depending perhaps on something
in an index.

As an example, below is a Vagrantfile that could be used for a web
development environment:

<pre class="prettyprint">
Vagrant.configure("2") do |config|
  config.vm.define "app" do |app|
    app.vm.provider "docker" do |d|
      d.build_dir = "."
      d.link "db"
    end
  end

  config.vm.define "db" do |app|
    app.vm.provider "docker" do |d|
      d.image = "paintedfox/postgresql"
      d.name = "db"
    end
  end
end
</pre>

In the example above, we build the "app" environment from a Dockerfile
that might build the container for our web application. This app environment
then links to the "db" environment which uses the "paintedfox/postgresql"
image to provide a PostgreSQL database.

And in both cases, synced folders work as you would expect with Vagrant,
so data can be persisted outside the containers and file modifications
can be mirrored back into the containers.

### Containers with SSH

The general approach to Docker containers is to have each container
be a single application instead of a complete multi-process system. In these
cases, SSH is unavailable so you can't take advantage of Vagrant features
such as `vagrant ssh`, provisioners, etc. However, if the container _does_
support SSH, then all these features are supported and do work.

For example, the Vagrantfile below uses
[baseimage](https://github.com/phusion/baseimage-docker) created by Phusion
which behaves more like a lightweight virtual machine.

<pre class="prettyprint">
Vagrant.configure("2") do |config|
  config.vm.provider "docker" do |d|
    d.cmd     = ["/sbin/my_init", "--enable-insecure-key"]
    d.image   = "phusion/baseimage"
    d.has_ssh = true
  end

  config.ssh.username = "root"
  config.ssh.private_key_path = "phusion.key"
end
</pre>

Assuming you have "phusion.key" in place, the above will start the container,
wait for SSH, and run any provisioners, set any hostnames, etc. Additionally,
`vagrant ssh` works perfectly.

And again, all of these features work whether you're running Docker natively
or running Docker via an automatically managed host VM from Vagrant.

### Docker-Specific Enhancements

So far, the behavior and workflow of using Docker with Vagrant has been
identical to if you had been using Vagrant with VirtualBox, VMware, or a
cloud service such as EC2.

However, Vagrant 1.6 does introduce some new commands that are made
specifically for the Docker provider to give some additional utility to
Vagrant.

`docker-logs` shows the logs from a container and optionally allows you
to tail the logs. For single-process (non-SSH) containers, this is a great
way to watch the output of the process. An example is shown below:

<pre class="prettyprint">
$ vagrant docker-logs web
Server listening on port 3000...
GET / 200 62.4ms
GET /images/header.png 200 3.1ms
GET /images/footer.png 200 2.8ms
</pre>

`docker-run` allows you to execute one-off commands in new containers.
Along with synced folders, this is useful for some environments. For example,
if you wanted to run tests in a Rails environment, it might look like the
following:

<pre class="prettyprint">
$ vagrant docker-run web -- rake test:unit
...
</pre>

### Next

The Docker provider allows Vagrant to manage development environments
with Docker-managed Linux containers. This lets users of Vagrant use this
style of development where it makes sense, without sacrificing the workflow
of any other development environments.

We're now nearing the release of Vagrant 1.6! The feature previews are just
about over and we're excited to gear up for a release shortly.
