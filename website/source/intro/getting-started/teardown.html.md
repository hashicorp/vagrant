---
layout: "intro"
page_title: "Teardown - Getting Started"
sidebar_current: "gettingstarted-teardown"
description: |-
  We now have a fully functional virtual machine we can use for basic
  web development. But now let us say it is time to switch gears, maybe work
  on another project, maybe go out to lunch, or maybe just time to go home.
  How do we clean up our development environment?
---

# Teardown

We now have a fully functional virtual machine we can use for basic
web development. But now let us say it is time to switch gears, maybe work
on another project, maybe go out to lunch, or maybe just time to go home.
How do we clean up our development environment?

With Vagrant, you _suspend_, _halt_, or _destroy_ the guest machine.
Each of these options have pros and cons. Choose the method that works
best for you.

**Suspending** the virtual machine by calling `vagrant suspend` will
save the current running state of the machine and stop it. When you are
ready to begin working again, just run `vagrant up`, and it will be
resumed from where you left off. The main benefit of this method is that it
is super fast, usually taking only 5 to 10 seconds to stop and start your
work. The downside is that the virtual machine still eats up your disk space,
and requires even more disk space to store all the state of the virtual
machine RAM on disk.

**Halting** the virtual machine by calling `vagrant halt` will gracefully
shut down the guest operating system and power down the guest machine.
You can use `vagrant up` when you are ready to boot it again. The benefit of
this method is that it will cleanly shut down your machine, preserving the
contents of disk, and allowing it to be cleanly started again. The downside is
that it'll take some extra time to start from a cold boot, and the guest machine
still consumes disk space.

**Destroying** the virtual machine by calling `vagrant destroy` will remove
all traces of the guest machine from your system. It'll stop the guest machine,
power it down, and remove all of the guest hard disks. Again, when you are ready to
work again, just issue a `vagrant up`. The benefit of this is that _no cruft_
is left on your machine. The disk space and RAM consumed by the guest machine
is reclaimed and your host machine is left clean. The downside is that
`vagrant up` to get working again will take some extra time since it
has to reimport the machine and re-provision it.

## Next Steps

You have successfully suspended, halted, and destroyed your virtual environment
with Vagrant. Read on to learn how to
[rebuild the environment](/intro/getting-started/rebuild.html).
