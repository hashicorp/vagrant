---
layout: "docs"
page_title: "Docker - Provisioning"
sidebar_current: "provisioning-docker"
description: |-
  The Vagrant Docker provisioner can automatically install Docker, pull Docker
  containers, and configure certain containers to run on boot.
---

# Docker Provisioner

**Provisioner name: `"docker"`**

The Vagrant Docker provisioner can automatically install
[Docker](https://www.docker.io), pull Docker containers, and configure certain
containers to run on boot.

The docker provisioner is ideal for organizations that are using
Docker as a means to distribute things like their application or services.
Or, if you are just getting started with Docker, the Docker provisioner
provides the easiest possible way to begin using Docker since the provisioner
automates installing Docker for you.

As with all provisioners, the Docker provisioner can be used along with
all the other provisioners Vagrant has in order to setup your working
environment the best way possible. For example, perhaps you use Puppet to
install services like databases or web servers but use Docker to house
your application runtime. You can use the Puppet provisioner along
with the Docker provisioner.

<div class="alert alert-info">
  <strong>Note:</strong> This documentation is for the Docker
      <em>provisioner</em>. If you are looking for the Docker
  <em>provider</em>, visit the
  <a href="/docs/docker/">Docker provider documentation</a>.
</div>

## Options

The docker provisioner takes various options. None are required. If
no options are required, the Docker provisioner will only install Docker
for you (if it is not already installed).

* `images` (array) - A list of images to pull using `docker pull`. You
  can also use the `pull_images` function. See the example below this
  section for more information.

In addition to the options that can be set, various functions are available
and can be called to configure other aspects of the Docker provisioner. Most
of these functions have examples in more detailed sections below.

* `build_image` - Build an image from a Dockerfile.

* `pull_images` - Pull the given images. This does not start these images.

* `post_install_provisioner` - A [provisioner block](/docs/provisioning) that runs post docker
   installation.

* `run` - Run a container and configure it to start on boot. This can
  only be specified once.

## Building Images

The provisioner can automatically build images. Images are built prior to
any configured containers to run, so you can build an image before running it.
Building an image is easy:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "docker" do |d|
    d.build_image "/vagrant/app"
  end
end
```

The argument to build an image is the path to give to `docker build`. This
must be a path that exists within the guest machine. If you need to get data
to the guest machine, use a synced folder.

The `build_image` function accepts options as a second parameter. Here
are the available options:

* `args` (string) - Additional arguments to pass to `docker build`. Use this
  to pass in things like `-t "foo"` to tag the image.

## Pulling Images

The docker provisioner can automatically pull images from the
Docker registry for you. There are two ways to specify images to
pull. The first is as an array using `images`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "docker",
    images: ["ubuntu"]
end
```

This will cause Vagrant to pull the "ubuntu" image from the registry
for you automatically.

The second way to pull images is to use the `pull_images` function.
Each call to `pull_images` will _append_ the images to be pulled. The
`images` variable, on the other hand, can only be used once.

Additionally, the `pull_images` function cannot be used with the
simple configuration method for provisioners (specifying it all in one line).

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "docker" do |d|
    d.pull_images "ubuntu"
    d.pull_images "vagrant"
  end
end
```

## Running Containers

In addition to pulling images, the Docker provisioner can run and start
containers for you. This lets you automatically start services as part of
`vagrant up`.

Running containers can only be configured using the Ruby block syntax with
the `do...end` blocks. An example of running a container is shown below:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "docker" do |d|
    d.run "rabbitmq"
  end
end
```

This will `docker run` a container with the "rabbitmq" image. Note that
Vagrant uses the first parameter (the image name by default) to override any
settings used in a previous `run` definition. Therefore, if you need to run
multiple containers from the same image then you must specify the `image`
option (documented below) with a unique name.

In addition to the name, the `run` method accepts a set of options, all optional:

* `image` (string) - The image to run. This defaults to the first argument
  but can also be given here as an option.

* `cmd` (string) - The command to start within the container. If not specified,
  then the container's default command will be used, such as the
  "CMD" command [specified in the `Dockerfile`](https:/docs.docker.io/en/latest/use/builder/#cmd).

* `args` (string) - Extra arguments for [`docker run`](https:/docs.docker.io/en/latest/commandline/cli/#run)
  on the command line. These are raw arguments that are passed directly to Docker.

* `auto_assign_name` (boolean) - If true, the `--name` of the container will
  be set to the first argument of the run. By default this is true. If the
  name set contains a "/" (because of the image name), it will be replaced
  with "-". Therefore, if you do `d.run "foo/bar"`, then the name of the
  container will be "foo-bar".

* `daemonize` (boolean) - If true, the "-d" flag is given to `docker run` to
  daemonize the containers. By default this is true.

* `restart` (string) - The restart policy for the container. Defaults to
  "always"

For example, here is how you would configure Docker to run a container
with the Vagrant shared directory mounted inside of it:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "docker" do |d|
    d.run "ubuntu",
      cmd: "bash -l",
      args: "-v '/vagrant:/var/www'"
  end
end
```

In case you need to run multiple containers based off the same image, you can do
so by providing different names and specifying the `image` parameter to it:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "docker" do |d|
    d.run "db-1", image: "user/mysql"
    d.run "db-2", image: "user/mysql"
  end
end
```

## Other

This section documents some other things related to the Docker provisioner
that are generally useful to know if you are using this provisioner.

### Customize `/etc/default/docker`

To customize this file, use the `post_install_provisioner` shell provisioner.

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "docker" do |d|
    d.post_install_provision "shell", inline:"echo export http_proxy='http://127.0.0.1:3128/' >> /etc/default/docker"
    d.run "ubuntu",
      cmd: "bash -l",
      args: "-v '/vagrant:/var/www'"
  end
end
```
