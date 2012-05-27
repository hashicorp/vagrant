---
layout: documentation
title: Changes - 0.5.x to 0.6.x
---
# Changes from Vagrant 0.5.x to 0.6.x

Vagrant 0.6.0 is the biggest release for Vagrant ever, with over
200 commits touching over 200 files. The goal of Vagrant 0.6 was
mainly to increase user-friendliness while also adding a couple
very important features along the way. There was also a lot of
internal cleanup to make way for _plugins_, explained below.

First, there are **backwards incompatible** changes! Please make
sure to run `vagrant upgrade_to_060` on all your previously made
Vagrant environments which will automatically handle upgrading them.

## User Friendliness Improved

Until this point, Vagrant has mostly relayed errors via giant
stack traces. Vagrant users were never quite sure whether there was
a bug or if they did something wrong! With Vagrant 0.6, all known
error cases which aren't bugs output friendly error messages with
no giant stack trace.

If you see a stack trace now: it is a bug, please report it.

## Validated Vagrantfiles

Somewhat related to the above, previously if you entered incorrect
values into a Vagrantfile (try to forward the port of a string, for
example), then a stack trace would more than likely erupt at some
point during the VM creation process. This was very frustrating since
the stack trace was never descriptive of what went wrong, and the
user could have possibly just waited minutes before an error was even
raised.

Vagrantfiles are now validated before any actions are taken on any
VMs. If there is invalid data in the Vagrantfile, then you'll get a
helpful error message explaining what is invalid and what was expected.

If there are any validations missing, please let me know and I'll add
them.

## Plugins

A long-planned feature (since Vagrant 0.1!) but the time wasn't right
until now. Vagrant has finally grown to the point where the core is quite
stable, and it was time to add this feature. **Plugins are now here.**
Plugins are a way for 3rd parties to extend Vagrant and be treated as
first-class citizens. The powers of plugins:

* Add new commands to the `vagrant` binary.
* Add new configuration options for Vagrantfiles, such as `config.my_plugin`.
* Modify functionality of built-in Vagrant actions. For example: You can add
  new steps for the `up` sequence.

The method by which plugins are installed and used is covered in the
[plugins documentation](/docs/plugins.html). For a full guide on extending
vagrant, see [the "Extending Vagrant" page](/docs/extending/index.html).

**Note:** The plugin API is not finalized. But please make plugins! Your
experiences will help guide the plugin API to a final state.

## Complete Changelog

The complete changelog from 0.5.4 to 0.6.0 can be found at the following URL:

[http://github.com/mitchellh/vagrant/blob/master/CHANGELOG.md](http://github.com/mitchellh/vagrant/blob/master/CHANGELOG.md)
