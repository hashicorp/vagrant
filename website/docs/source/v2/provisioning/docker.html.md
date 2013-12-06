---
page_title: "Docker - Provisioning"
sidebar_current: "provisioning-docker"
---

# Docker Provisioner

**Provisioner name: `"docker"`**

The docker provisioner can automatically install [Docker](http://www.docker.io),
pull Docker containers, and configure certain containers to run on boot.

The docker provisioner is ideal for organizations that are using
Docker as a means to distribute things like their application or services.
Or, if you're just getting started with Docker, the Docker provisioner
provides the easiest possible way to begin using Docker since the provisioner
automates installing Docker for you.

As with all provisioners, the Docker provisioner can be used along with
all the other provisioners Vagrant has in order to setup your working
environment the best way possible. For example, perhaps you use Puppet to
install services like databases or web servers but use Docker to house
your application runtime. You can use the Puppet provisioner along
with the Docker provisioner.

## Options

The docker provisioner takes various options. None are required. If
no options are required, the Docker provisioner will only install Docker
for you (if it isn't already installed).

* `images` (array) - A list of images to pull using `docker pull`. You
  can also use the `pull_images` function. See the example below this
  section for more information.

* `version` (string) - The version of Docker to install. This defaults to
  "latest" and will install the latest version of Docker.

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

This will `docker run` a container with the "rabbitmq" image. In addition
to the name, the `run` method accepts a set of options, all optional:

* `image` (string) - The image to run. This defaults to the first argument
  but can also be given here as an option.

* `cmd` (string) - The command to start within the container. If not specified,
  then the containers default "run" command will be used, such as the
  "run" command specified when the container was built.

* `args` (string) - Extra arguments for `docker run` on the command line.
  These are raw arguments that are passed directly to Docker.

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
