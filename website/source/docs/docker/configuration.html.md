---
layout: "docs"
page_title: "Configuration- Docker Provider"
sidebar_current: "providers-docker-configuration"
description: |-
  The Docker provider has some provider-specific configuration options
  you may set. A complete reference is shown on this page.
---

# Docker Configuration

The Docker provider has some provider-specific configuration options
you may set. A complete reference is shown below.

### Required

  * `build_dir` (string) - The path to a directory containing a Dockerfile.
    One of this or `image` is required.

  * `image` (string) - The image to launch, specified by the image ID or a name
    such as `ubuntu:12.04`. One of this or `build_dir` is required.

### Optional

General settings:

  * `build_args` (array of strings) - Extra arguments to pass to
      `docker build` when `build_dir` is in use.

  * `cmd` (array of strings) - Custom command to run on the container.
    Example: `["ls", "/app"]`.

  * `compose` (boolean) - If true, Vagrant will use `docker-compose` to
    manage the lifecycle and configuration of containers. This defaults
    to false.

  * `compose_configuration` (Hash) - Configuration values used for populating
    the `docker-compose.yml` file. The value of this Hash is directly merged
    and written to the `docker-compose.yml` file allowing customization of
    non-services items like networks and volumes.

  * `create_args` (array of strings) - Additional arguments to pass to
    `docker run` when the container is started. This can be used to set
    parameters that are not exposed via the Vagrantfile.

  * `dockerfile` (string) - Name of the Dockerfile in the build directory.
    This defaults to "Dockerfile"

  * `env` (hash) - Environmental variables to expose into the container.

  * `expose` (array of integers) - Ports to expose from the container
    but not to the host machine. Useful for links.

  * `link` (method, string argument) - Link this container to another
    by name. The argument should be in the format of `(name:alias)`.
    Example: `docker.link("db:db")`. Note, if you are linking to
    another container in the same Vagrantfile, make sure you call
    `vagrant up` with the `--no-parallel` flag.

  * `force_host_vm` (boolean) - If true, then a host VM will be spun up
    even if the computer running Vagrant supports Linux containers. This
    is useful to enforce a consistent environment to run Docker. This value
    defaults to "false" on Linux, Mac, and Windows hosts and defaults to "true"
    on other hosts. Users on other hosts who choose to use a different Docker
    provider or opt-in to the native Docker builds can explicitly set this
    value to false to disable the behavior.

  * `has_ssh` (boolean) - If true, then Vagrant will support SSH with
    the container. This allows `vagrant ssh` to work, provisioners, etc.
    This defaults to false.

  * `host_vm_build_dir_options` (hash) - Synced folder options for the
    `build_dir`, since the build directory is synced using a synced folder
    if a host VM is in use.

  * `name` (string) - Name of the container. Note that this has to be unique
    across all containers on the host VM. By default Vagrant will generate
    some random name.

  * `pull` (bool) - If true, the image will be pulled on every `up` and
    `reload`. Defaults to false.

  * `ports` (array of strings) - Ports to expose from the container to the
    host. These should be in the format of `host:container`.

  * `remains_running` (boolean) - If true, Vagrant expects this container
    to remain running and will make sure that it does for a certain amount
    of time. If false, then Vagrant expects that this container will
    automatically stop at some point, and will not error if it sees it do that.

  * `stop_timeout` (integer) - The amount of time to wait when stopping
    a container before sending a SIGTERM to the process.

  * `vagrant_machine` (string) - The name of the Vagrant machine in the
    `vagrant_vagrantfile` to use as the host machine. This defaults to
    "default".

  * `vagrant_vagrantfile` (string) - Path to a Vagrantfile that contains
    the `vagrant_machine` to use as the host VM if needed.

  * `volumes` (array of strings) - List of directories to mount as
    volumes into the container. These directories must exist in the
    host where Docker is running. If you want to sync folders from the
    host Vagrant is running, just use synced folders.

Below, we have settings related to auth. If these are set, then Vagrant
will `docker login` prior to starting containers, allowing you to pull
images from private repositories.

  * `email` (string) - Email address for logging in.

  * `username` (string) - Username for logging in.

  * `password` (string) - Password for logging in.

  * `auth_server` (string) - The server to use for authentication. If not
      set, the Docker Hub will be used.
