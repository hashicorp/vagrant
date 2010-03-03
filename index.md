---
layout: default
title: Welcome
---

<img src="/images/vagrant_chilling.png" class="left" />

Vagrant is a tool set out to **change the way web developers work**.

Vagrant quickly and seamlessly builds and provisions virtual machines for
development using [Sun's VirtualBox](http://www.virtualbox.org). Using vagrant,
developers can continue to manage project files using their own system and editors,
but all the servers, processes, etc. actually run within a virtualized environment.
Vagrant allows ports to be forwarded so you can still test a web service, for example,
by forwarding the virtual machine's port 80 to some port on the host machine and
visiting it in any browser.

Are you ready to use vagrant to revolutionize the way you work? Check out
the [getting started guide](/docs/getting_started.html).

<div class="clear"> </div>

## Why Use Vagrant?

* **Get up and running without worrying about server setup** - Instead of spending
  hours setting up a development environment for a project, simply run
  `vagrant up` and get coding!
* **Continue using your own editor and browser** - With shared folders and port forwarding,
  it feels exactly as if nothing has changed. You can still edit files using your favorite
  editor, and test the site using your favorite local tools.
* **Avoid dependency hell** - Every project which uses vagrant has its own _unique and isolated virtual environment_,
  so the dependencies and configurations of multiple projects never collide.
* **Cleanup when you're done** - When you're done working for the day, execute
  `vagrant down` and remove the virtual machine! No more web server, database, etc.
  processes running when they're not needed!
* **Add developers quickly and easily** - For teams, adding developers to new projects
  is often a pain, since the new developer needs to learn how to setup all the
  different pieces of the application to get it running on his development machine.
  Forget about it! Just tell him to pull the latest code base from version control
  and run `vagrant up` and you're in business!