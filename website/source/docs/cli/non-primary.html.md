---
layout: "docs"
page_title: "More Vagrant Commands - Command-Line Interface"
sidebar_current: "cli-nonprimary"
description: |-
  In addition to the commands listed in the sidebar and shown in "vagrant -h",
  Vagrant comes with some more commands that are hidden from basic help output.
  These commands are hidden because they're not useful to beginners or they're
  not commonly used. We call these commands "non-primary subcommands".
---

# More Commands

In addition to the commands listed in the sidebar and shown in `vagrant -h`,
Vagrant comes with some more commands that are hidden from basic help output.
These commands are hidden because they're not useful to beginners or they're
not commonly used. We call these commands "non-primary subcommands".

You can view all subcommands, including the non-primary subcommands,
by running `vagrant list-commands`, which itself is a non-primary subcommand!

Note that while you have to run a special command to list the non-primary
subcommands, you do not have to do anything special to actually _run_ the
non-primary subcommands. They're executed just like any other subcommand:
`vagrant COMMAND`.

The list of non-primary commands is below. Click on any command to learn
more about it.

* [docker-exec](/docs/docker/commands.html)
* [docker-logs](/docs/docker/commands.html)
* [docker-run](/docs/docker/commands.html)
* [rsync](/docs/cli/rsync.html)
* [rsync-auto](/docs/cli/rsync-auto.html)
