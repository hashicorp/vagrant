---
layout: "docs"
page_title: "Installing Vagrant from Source"
sidebar_current: "installation-source"
description: |-
  Installing Vagrant from source is an advanced topic and is only recommended
  when using the official installer is not an option. This page details the
  steps and prerequisites for installing Vagrant from source.
---

# Installing Vagrant from Source

Installing Vagrant from source is an advanced topic and is only recommended
when using the official installer is not an option. This page details the
steps and prerequisites for installing Vagrant from source.

## Install Ruby
You must have a modern Ruby (>= 2.2) in order to develop and build Vagrant. The
specific Ruby version is documented in the Vagrant's `gemspec`. Please refer to
the `vagrant.gemspec` in the repository on GitHub, as it will contain the most
up-to-date requirement. This guide will not discuss how to install and manage Ruby.
However, beware of the following pitfalls:

- Do **NOT** use the system Ruby - use a Ruby version manager like rvm or chruby
- Vagrant plugins are configured based on current environment. If plugins are installed
  using Vagrant from source, they will not work from the package based Vagrant installation.

## Clone Vagrant
Clone Vagrant's repository from GitHub into the directory where you keep code on your machine:


```shell
$ git clone https://github.com/mitchellh/vagrant.git
```

Next, `cd` into that path. All commands will be run from this path:

```shell
$ cd /path/to/your/vagrant/clone
```

Run the `bundle` command with a required version* to install the requirements:

```shell
$ bundle install
```

You can now run Vagrant by running `bundle exec vagrant` from inside that
directory.

## Use Locally
In order to use your locally-installed version of Vagrant in other projects, you will need to create a binstub and add it to your path.

First, run the following command from the Vagrant repo:

```shell
$ bundle --binstubs exec
```

This will generate files in `exec/`, including `vagrant`. You can now specify
the full path to the `exec/vagrant` anywhere on your operating system:

```shell
$ /path/to/vagrant/exec/vagrant init -m hashicorp/precise64
```

Note that you _will_ receive warnings that running Vagrant like this is not
supported. It's true. It's not. You should listen to those warnings.

If you do not want to specify the full path to Vagrant (i.e. you just want to
run `vagrant`), you can create a symbolic link to your exec:

```shell
$ ln -sf /path/to/vagrant/exec/vagrant /usr/local/bin/vagrant
```

When you want to switch back to the official Vagrant version, simply
remove the symlink.
