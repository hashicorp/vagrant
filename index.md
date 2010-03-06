---
layout: welcome
title: Welcome
---
Welcome to **sane development environments**.

While web technologies have progressed leaps and bounds in the past decade,
the techniques used for web development have remained rather stagnant. Ten
years ago, a PHP developer would start up Apache and MySQL on their local
machine and use that to "develop." Today, with the rise of more complex web
applications, complete with message queues, multiple database backends,
custom worker processes, and more, its surprising to see that this method of
development remains largely unchanged.

Vagrant is **here to change that.** By providing automated creation and
provisioning of virtual machines using [Sun's VirtualBox], Vagrant provides
the tools to create and configure lightweight, reproducible, and portable
virtual environments.

Are you ready to use vagrant to revolutionize the way you work? Check out
the [getting started guide](/docs/getting-started/index.html).

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