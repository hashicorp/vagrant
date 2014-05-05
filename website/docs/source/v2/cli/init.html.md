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

## Options

* `--force` - If specified, this command will overwite any existing
  `Vagrantfile`.

* `--minimal` - If specified, a minimal Vagrantfile will be created. This
  Vagrantfile does not contain the instructional comments that the normal
  Vagrantfile contains.

* `--output FILE` - This will output the Vagrantfile to the given file.
  If this is "-", the Vagrantfile will be sent to stdout.
