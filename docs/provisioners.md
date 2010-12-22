---
layout: documentation
title: Documentation - Provisioners
---
# Provisioners

Vagrant supports provisioning a project's VM through the use of _provisioners_,
since spinning up a blank virtual machine is not very useful! The provisioners
supported out-of-the-box with a Vagrant installation are: [Chef Solo](/docs/provisioners/chef_solo.html), 
[Chef Server](/docs/provisioners/chef_server.html), and [Puppet](/docs/provisioners/puppet.html). 
These provisioners allow you to easily setup your virtual machine with everything it needs to run as
a proper server (whether it be a web server, database server, utility server,
or all those things combined).

By default, Vagrant disables provisioning. Provisioning can be enabled by selecting
the provisioner using the `config.vm.provisioner` configuration key. The value
of this key is either a symbol to use a built-in provisioner, a class which
inherits from `Vagrant::Provisioners::Base` for a custom solution, or `nil`
to disable it.

## Which Provisioner Should I Use?

Ah, with the freedom of choice comes the complication of choosing
what is right for you.

* **Chef Solo** - Chef solo is most ideal if you're just getting started with
  chef or a chef server is simply too heavy for your situation. Chef solo allows
  you to embed all your cookbooks within your project as well, which is nice for
  projects which want to keep track of their cookbooks within the same repository.
  Chef solo runs standalone -- it requires no chef server or any other server to
  talk to; it simply runs by itself on the VM.
* **Chef Server** - Chef server is useful for companies or individuals which
  manage many projects, since it allows you to share cookbooks across multiple
  projects. The cookbooks themselves are stored on the server, and the client
  downloads the cookbooks upon running.
* **Puppet** - The Puppet provisioners runs stand-alone Puppet manifests that are 
  stored on the server and downloaded to the client VM when it is created.  The
  provisioner does not require a Puppet server and runs on the VM itself.
* **Other tools, shell scripts, etc.** - Do you use something other than that which
  is built into Vagrant? Provisioners are simply subclasses of `Vagrant::Provisioners::Base`,
  meaning you can easily build your own, should the need arise.
