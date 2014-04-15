---
page_title: "Vagrant 1.6 Feature Preview: Global Status and Control"
title: "Feature Preview: Global Status and Control"
author: "Mitchell Hashimoto"
author_url: https://github.com/mitchellh
---

Vagrant 1.5 was released just a month ago, but we already have big changes
lined up for Vagrant 1.6. To prepare you for the release of 1.6, we're
restarting our weekly "feature preview" blog post series to cover the new
features that are on the way.

The first new feature we'll be covering is something we're calling
_global status and control_.

Global status introduces a new `global-status` command to Vagrant that
will show you the status of all created Vagrant environments on your system.
You'll never again forget what Vagrant environments are running, not
running, or using resources on your system.

Global control lets you use a unique ID assigned to each of your Vagrant
environments to control it from any directory, not only the directory
where the Vagrantfile is. This is useful in many situations, but perhaps
this is most useful when you forget to destroy a Vagrant environment. You
can now destroy that Vagrant environment from anywhere!

With these two features Vagrant environment management becomes much easier.

Read on to learn more.

READMORE

### Global Status

A new command `global-status` is available in Vagrant 1.6. This command
tracks all _created_ Vagrant environments. An example of the output is
shown below:

```
$ vagrant global-status
id       name    provider           state              directory
---------------------------------------------------------------------
4174bb6  web     virtualbox         stopped            c:/hashicorp/foo
72a2e4d  default vmware_workstation running            c:/hashicorp/bar
865a979  default virtualbox         suspended          c:/hashicorp/baz
```

Global status gives you a few bits of information about the machine:
an ID, the name and provider of the machine, the last known state,
and the directory it last saw that machine.

This at-a-glance information is enough to tell you what is and isn't
running. To get more information about an environment, you can go to
the directory for that machine and use the normal `vagrant` commands to
inspect the environment.

Or, you can use global control, covered next.

### Global Control

Global control lets you control a Vagrant environment from any directory,
not only the directory where the Vagrantfile for that environment exists.

In Vagrant 1.5 and earlier, you had to be in the same directory as the
Vagrantfile, or any sub-directory of the Vagrantfile. With Vagrant 1.6,
you can use the ID from `global-status` to control the machine.

For example, if you want to SSH into one of the machines from above, you
can be in any terminal and do this:

```
$ vagrant ssh 72a2e4d
Welcome to Ubuntu 12.04.3 LTS (GNU/Linux 3.8.0-29-generic x86_64)

vagrant@vagrant:~$
```

The ID "72a2e4d" is from the ID column in the `global-status` output
above. You can use this ID for any Vagrant command, such as `destroy`,
`up`, `suspend`, etc.

In addition to the built-in commands, using an ID should work with
any existing Vagrant plugins as well without any modifications.

### Next

Vagrant 1.6 has some huge features. We're starting off this feature
preview series with one of the smaller features, but it is still incredibly
useful.

Watch out next week for the next post in the feature preview series, where
we'll be covering what I think is a monumental feature addition to Vagrant.
