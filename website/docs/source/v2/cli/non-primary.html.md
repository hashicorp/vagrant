---
page_title: "More Vagrant Commands - Command-Line Interface"
sidebar_current: "cli-nonprimary"
---

# More Commands

In addition to the commands listed in the sidebar and shown in `vagrant -h`,
Vagrant comes with some more commands that are hidden from basic help output.
These commands are hidden because they're not useful to beginners or they're
not commonly used. We call these commands "non-primary subcommands".

You can view all subcommands, including the non-primary subcommands,
by running `vagrant list-commands`, which itself is a non-primary subcommand!

Note that while you have to run a special command to list the non-primary
subcommands, you don't have to do anything special to actually _run_ the
non-primary subcommands. They're executed just like any other subcommand:
`vagrant COMMAND`.

The list of non-primary commands is below. Click on any command to learn
more about it.

* [docker-logs](/v2/docker/commands.html)
* [docker-run](/v2/docker/commands.html)
* [rsync](/v2/cli/rsync.html)
* [rsync-auto](/v2/cli/rsync-auto.html)
