# Vagrant Buildbot System

This is the code for the Vagrant buildbot system. [Buildbot](http://buildbot.net)
is a continuous integration system that offers an extreme amount
of flexibility and power.

This directory contains a few subdirectories to setup this CI system:

* `buildbot_config` - This contains the custom Python code to setup the
  various parts of the buildbot configuration.
* `master` - This is mostly auto-generated from Buildbot itself, however
  the `master.cfg` file is the configuration used on the buildmaster.
* `slave`- This is mostly auto-generated from Buildbot, but the
  `buildbot.tac` contains some custom code in it to connect to the Vagrant
  buildmaster.

**NOTE:** One of the dependencies for the Vagrant CI system is currently
not public, and as such can't be setup by the general public. This will be
fixed in the next couple weeks.

## Contribute a CI Slave!

**NOTE:** The slave contribution process is still not completely setup and
will be ironed out very soon after the CI system is up and running.

Vagrant is an open source profit which doesn't have any income from support,
services, or otherwise. All Vagrant slave machines are donated by the
community. Donating a machine doesn't require anything more than installing
and running the slave software. Vagrant is specifically looking for slave
machines that provide a diverse set of operating systems and cpu architectures
for testing Vagrant.

## Setting up the Buildmaster

To set up the buildmaster, clone out this directory somewhere and install
the dependencies:

    pip install -r requirements.txt

Once the dependencies are installed, create a configuration file with the
settings you want to use somewhere. The settings available for a master are
defined in `buildbot_config/config/master.py`. An example configuration file:

    [master]
    slaves=foo:password,bar:anotherpassword
    web_port=8000

Execute the buildbot using:

    BUILDBOT_CONFIG=/path/to/my/config.cfg buildbot start master/

## Setting up a Buildslave

To set up a slave, clone out this directory and install the dependencies:

    pip install -r requirements.txt

Then, create a configuration file with the slave settings. The settings
available for a slave are defined in `buildbot_config/config/slave.py`.
An example configuration file:

    [slave]
    master_host=ci.vagrantup.com
    master_port=9989
    name=the-love-machine
    password=foobarbaz

Note that the password above will be assigned to you as part of donating
any slave machine, since it must be setup on the buildmaster side as well.
Once the configuration is done, run the slave:

    BUILDBOT_CONFIG=/path/to/my/config.cfg buildslave start slave/
