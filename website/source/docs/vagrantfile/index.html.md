---
layout: "docs"
page_title: "Vagrantfile"
sidebar_current: "vagrantfile"
description: |-
  The primary function of the Vagrantfile is to describe the type
  of machine required for a project, and how to configure and
  provision these machines. Vagrantfiles are called Vagrantfiles because
  the actual literal filename for the file is "Vagrantfile".
---

# Vagrantfile

The primary function of the Vagrantfile is to describe the type
of machine required for a project, and how to configure and
provision these machines. Vagrantfiles are called Vagrantfiles because
the actual literal filename for the file is `Vagrantfile` (casing does not
matter unless your file system is running in a strict case sensitive mode).

Vagrant is meant to run with one Vagrantfile per project, and the Vagrantfile
is supposed to be committed to version control. This allows other developers
involved in the project to check out the code, run `vagrant up`, and be on
their way. Vagrantfiles are portable across every platform Vagrant supports.

The syntax of Vagrantfiles is [Ruby](http://www.ruby-lang.org), but knowledge
of the Ruby programming language is not necessary to make modifications to the
Vagrantfile, since it is mostly simple variable assignment. In fact, Ruby is not
even the most popular community Vagrant is used within, which should help show
you that despite not having Ruby knowledge, people are very successful with
Vagrant.

## Lookup Path

When you run any `vagrant` command, Vagrant climbs up the directory tree
looking for the first Vagrantfile it can find, starting first in the
current directory. So if you run `vagrant` in `/home/mitchellh/projects/foo`,
it will search the following paths in order for a Vagrantfile, until it
finds one:

```
/home/mitchellh/projects/foo/Vagrantfile
/home/mitchellh/projects/Vagrantfile
/home/mitchellh/Vagrantfile
/home/Vagrantfile
/Vagrantfile
```

This feature lets you run `vagrant` from any directory in your project.

You can change the starting directory where Vagrant looks for a Vagrantfile
by setting the `VAGRANT_CWD` environmental variable to some other path.

<a name="load-order"></a>
## Load Order and Merging

An important concept to understand is how Vagrant loads Vagrantfiles. Vagrant
actually loads a series of Vagrantfiles, merging the settings as it goes. This
allows Vagrantfiles of varying level of specificity to override prior settings.
Vagrantfiles are loaded in the order shown below. Note that if a Vagrantfile
is not found at any step, Vagrant continues with the next step.

1. Vagrantfile packaged with the [box](/docs/boxes.html) that is to be used
  for a given machine.
2. Vagrantfile in your Vagrant home directory (defaults to `~/.vagrant.d`).
  This lets you specify some defaults for your system user.
3. Vagrantfile from the project directory. This is the Vagrantfile that you will
  be modifying most of the time.
4. [Multi-machine overrides](/docs/multi-machine/) if any.
5. [Provider-specific overrides](/docs/providers/configuration.html),
   if any.

At each level, settings set will be merged with previous values. What this
exactly means depends on the setting. For most settings, this means that
the newer setting overrides the older one. However, for things such as defining
networks, the networks are actually appended to each other. By default, you
should assume that settings will override each other. If the behavior is
different, it will be noted in the relevant documentation section.

Within each Vagrantfile, you may specify multiple `Vagrant.configure` blocks.
All configurations will be merged within a single Vagrantfile in the order
they're defined.

## Available Configuration Options

You can learn more about the available configuration options by clicking
the relevant section in the left navigational area.
