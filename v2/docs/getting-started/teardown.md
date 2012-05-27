---
layout: getting_started
title: Getting Started - Teardown

current: Teardown
previous: Packaging
previous_url: /docs/getting-started/packaging.html
next: Rebuild Instantly
next_url: /docs/getting-started/rebuild.html
---
# Teardown

We now have a fully functional virtual machine which can be used
for basic web development. We've packaged this virtual machine up
and we've given it to other members of our team. But now let's say its time to
switch gears, maybe work on another project, maybe go out to lunch,
or maybe just go home. What do we do to clean up our development
environment?

There are three options to clean up your environment:

1. Suspending
1. Halting
1. Destroying

Each of these options and their pros and cons will be covered below.

## Suspending the Environment

One option is to _suspend the virtual machine_ by running `vagrant suspend`.
This will save the current running state of your virtual machine and then
stop it. To resume working again at some other time, simply issue a `vagrant resume`
to get going!

The main benefit of this is that resuming your work again is quick, a matter
of maybe 10 to 15 seconds. The cost is that your disk space is still consumed
by the virtual machine. An average virtual machine takes up about 1 GB of disk
space.

## Halting the Environment

Another option is to _halt the virtual machine_ by running `vagrant halt`.
This will attempt a graceful shutdown of your VM (such as issuing a `halt`
in a linux machine) and wait for it to shut down. To resume working again,
issue a `vagrant up`, which will reboot the machine but will not repeat
the import sequence (since its already imported).

The main benefit of this is it allows you to cleanly shut down your VM,
and allow it from a cold state again. The cost is that you still pay
for the disk space that is consumed by the virtual machine.

## Destroying the Environment

Finally, you can _completely destroy the virtual environment_. This can be
done by running `vagrant destroy` which will literally delete all traces of the
virtual environment off the disk. To get started again, run `vagrant up` and
your environment will be rebuilt.

The benefit of this is that your disk space is completely restored to
pre-VM state, saving you about 1 GB on average. The cost is that you must
wait for a full rebuild when you `vagrant up` again.

Typically you would not destroy the environment of an active project, unless
disk space is really at a premium. Instead, most users choose to suspend or
halt their projects instead.
