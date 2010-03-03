---
layout: getting_started
title: Getting Started - Teardown
---
# Teardown

We now have a fully functional virtual machine which can be used
for basic rails development. We've packaged this virtual machine up
and we've given it to other members of our team. But now lets say its time to
switch gears, maybe work on another project, maybe go out to lunch,
or maybe just go home. What do we do to clean up our development
environment?

## Suspending the Environment

One option is to _suspend the virtual machine_ by running `vagrant suspend`.
This will take a snapshot of the current [VirtualBox](http://www.virtualbox.org)
Vagrant has created and will stop it. To resume working again at some other
time, simply issue a `vagrant resume` to get going!

#### Pros

* Exact state is saved, the VM basically restarts at the last running instruction.
* Fast resume since there is no need to wait for Vagrant to rebuild the entire
  environment.

#### Cons

* Disk space is still consumed by Vagrant. An average virtual machine takes
  up about 500 MB of disk space. This is left on your system with a suspension.

## Destroying the Environment

The other option is to _completely destroy the virtual environment_. This
can be done by running `vagrant down` which will literally delete all traces
of the virtual environment off the disk. To get started again, simply run
a `vagrant up` and Vagrant will rebuild your environment.

#### Pros

* No trace left of the virtual environment. No disk space is used other than
  the configuration files.

#### Cons

* Rebuilding the VM will take a few minutes when `vagrant up` is ran.
