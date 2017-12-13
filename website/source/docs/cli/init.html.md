---
layout: "docs"
page_title: "vagrant init - Command-Line Interface"
sidebar_current: "cli-init"
description: |-
  The "vagrant init" command is used to initialize the current directory to be
  a Vagrant environment by creating an initial Vagrantfile.
---

# Init

**Command: `vagrant init [name [url]]`**

This initializes the current directory to be a Vagrant environment
by creating an initial [Vagrantfile](/docs/vagrantfile/) if
one does not already exist.

If a first argument is given, it will prepopulate the `config.vm.box`
setting in the created Vagrantfile.

If a second argument is given, it will prepopulate the `config.vm.box_url`
setting in the created Vagrantfile.

## Options

* `--box-version` - (Optional) The box version or box version constraint to add
  to the `Vagrantfile`.

* `--force` - If specified, this command will overwrite any existing
  `Vagrantfile`.

* `--minimal` - If specified, a minimal Vagrantfile will be created. This
  Vagrantfile does not contain the instructional comments that the normal
  Vagrantfile contains.

* `--output FILE` - This will output the Vagrantfile to the given file.
  If this is "-", the Vagrantfile will be sent to stdout.

* `--template FILE` - Provide a custom ERB template for generating the Vagrantfile.

## Examples

Create a base Vagrantfile:

```sh
$ vagrant init hashicorp/precise64
```

Create a minimal Vagrantfile (no comments or helpers):

```sh
$ vagrant init -m hashicorp/precise64
```

Create a new Vagrantfile, overwriting the one at the current path:

```sh
$ vagrant init -f hashicorp/precise64
```

Create a Vagrantfile with the specific box, from the specific box URL:

```sh
$ vagrant init my-company-box https://boxes.company.com/my-company.box
```

Create a Vagrantfile, locking the box to a version constraint:

```sh
$ vagrant init --box-version '> 0.1.5' hashcorp/precise64
```
