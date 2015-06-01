# Vagrant

* Website: [http://www.vagrantup.com](http://www.vagrantup.com)
* Source: [https://github.com/mitchellh/vagrant](https://github.com/mitchellh/vagrant)
* IRC: `#vagrant` on Freenode
* Mailing list: [Google Groups](http://groups.google.com/group/vagrant-up)

Vagrant is a tool for building and distributing development environments.

Development environments managed by Vagrant can run on local virtualized
platforms such as VirtualBox or VMware, in the cloud via AWS or OpenStack,
or in containers such as with Docker or raw LXC.

Vagrant provides the framework and configuration format to create and
manage complete portable development environments. These development
environments can live on your computer or in the cloud, and are portable
between Windows, Mac OS X, and Linux.

## Quick Start

For the quick-start, we'll bring up a development machine on
[VirtualBox](http://www.virtualbox.org) because it is free and works
on all major platforms. Vagrant can, however, work with almost any
system such as OpenStack, VMware, Docker, etc.

First, make sure your development machine has
[VirtualBox](http://www.virtualbox.org)
installed. After this,
[download and install the appropriate Vagrant package for your OS](http://www.vagrantup.com/downloads).

To build your first virtual environment:

    vagrant init hashicorp/precise32
    vagrant up

Note: The above `vagrant up` command will also trigger Vagrant to download the
`precise32` box via the specified URL. Vagrant only does this if it detects that
the box doesn't already exist on your system.

## Getting Started Guide

To learn how to build a fully functional development environment, follow the
[getting started guide](http://docs.vagrantup.com/v2/getting-started/index.html).

## Installing the Gem from Git

If you want the bleeding edge version of Vagrant, we try to keep master pretty stable
and you're welcome to give it a shot. The following is an example showing how to do this:

    rake install

Ruby 2.0 is needed.

## Contributing to Vagrant

### Dependencies and Unit Tests

To hack on Vagrant, you'll need [bundler](http://github.com/carlhuda/bundler) which can
be installed with a simple `gem install bundler`. Afterwards, do the following:

    bundle install
    rake

This will run the unit test suite, which should come back all green! Then you're good to go!

If you want to run Vagrant without having to install the gem, you may use `bundle exec`,
like so:

    bundle exec vagrant help

**NOTE:** By default running Vagrant via `bundle` will disable plugins.
This is necessary because Vagrant creates its own private Bundler context
(it does not respect your Gemfile), because it uses Bundler to manage plugin
dependencies.

### Acceptance Tests

Vagrant also comes with an acceptance test suite that does black-box
tests of various Vagrant components. Note that these tests are **extremely
slow** because actual VMs are spun up and down. The full test suite can
take hours. Instead, try to run focused component tests.

To run the acceptance test suite, first copy `vagrant-spec.config.example.rb`
to `vagrant-spec.config.rb` and modify it to valid values. The places you
should fill in are clearly marked.

Next, see the components that can be tested:

```
$ rake acceptance:components
cli
provider/virtualbox/basic
...
```

Then, run one of those components:

```
$ rake acceptance:run COMPONENTS="cli"
...
```
