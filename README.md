# Vagrant

* Website: [http://www.vagrantup.com](http://www.vagrantup.com)
* Source: [https://github.com/mitchellh/vagrant](https://github.com/mitchellh/vagrant)
* IRC: `#vagrant` on Freenode
* Mailing list: [Google Groups](http://groups.google.com/group/vagrant-up)

Vagrant is a tool for building and distributing development environments.

Vagrant provides the framework and configuration format to create and
manage complete portable development environments. These development
environments can live on your computer or in the cloud, and are portable
between Windows, Mac OS X, and Linux.

## Quick Start

First, make sure your development machine has [VirtualBox](http://www.virtualbox.org)
installed. After this, [download and install the appropriate Vagrant package for your OS](http://downloads.vagrantup.com). If you're not on Mac OS X or Windows, you'll need
to add `/opt/vagrant/bin` to your `PATH`. After this, you're ready to go!

To build your first virtual environment:

    vagrant init precise32 http://files.vagrantup.com/precise32.box
    vagrant up

Note: The above `vagrant up` command will also trigger Vagrant to download the
`precise32` box via the specified URL. Vagrant only does this if it detects that
the box doesn't already exist on your system.

## Getting Started Guide

To learn how to build a fully functional rails development environment, view the
[getting started guide](http://vagrantup.com/v1/docs/getting-started/index.html).

## Installing the Gem from Git

If you want the bleeding edge version of Vagrant, we try to keep master pretty stable
and you're welcome to give it a shot. The following is an example showing how to do this:

    rake install

## Contributing to Vagrant

### Dependencies and Unit Tests

To hack on vagrant, you'll need [bundler](http://github.com/carlhuda/bundler) which can
be installed with a simple `gem install bundler`. Afterwords, do the following:

    bundle install
    rake

This will run the unit test suite, which should come back all green! Then you're good to go!

If you want to run Vagrant without having to install the gem, you may use `bundle exec`,
like so:

    bundle exec bin/vagrant help

### Acceptance Tests

Vagrant also comes with an acceptance test suite which runs the system
end-to-end, without mocking out any dependencies. Note that this test
suite is **extremely slow**, with the test suite taking hours on even
a decent system. A CI will be setup in due time to run these tests
automatically. However, it is still useful to know how to run these
tests since it is often useful to run a single test if you're working
on a specific feature.

The acceptance tests have absolutely _zero_ dependence on the Vagrant
source. Instead, an external configuration file must be used to give
the acceptance tests some parameters (such as what Vagrant version is
running, where the Vagrant `vagrant` binary is, etc.). If you want to
run acceptance tests against source, or just want to see an example of
this file, you can generate it automatically for the source code:

    rake acceptance:config

This will drop an `acceptance_config.yml` file in your working directory.
You can then run a specific acceptance test like so:

    ACCEPTANCE_CONFIG=./acceptance_config.yml ruby test/acceptance/version_test.rb

That's it!

If you're developing an acceptance test and you're unsure why things
might be failing, you can also view log output for the acceptance tests,
which can be very verbose but are a great help in finding bugs:

    ACCEPTANCE_LOGGING=debug ACCEPTANCE_CONFIG=./acceptance_config.yml ruby test/acceptance/version_test.rb
