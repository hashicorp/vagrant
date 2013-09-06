---
page_title: "vagrant init - Command-Line Interface"
sidebar_current: "cli-init"
---

# Init

**Command: `vagrant init [box-name] [box-url]`**

This initializes the current directory to be a Vagrant environment
by creating an initial [Vagrantfile](/v2/vagrantfile/index.html) if
one doesn't already exist.

If a first argument is given, it will prepopulate the `config.vm.box`
setting in the created Vagrantfile.

If a second argument is given, it will prepopulate the `config.vm.box_url`
setting in the created Vagrantfile.
