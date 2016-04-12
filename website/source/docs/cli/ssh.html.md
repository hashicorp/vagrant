---
layout: "docs"
page_title: "vagrant ssh - Command-Line Interface"
sidebar_current: "cli-ssh"
description: |-
  The "vagrant ssh" command is used to establish an SSH session into a running
  virtual machine to give you shell access.
---

# SSH

**Command: `vagrant ssh [name|id] [-- extra_ssh_args]`**

This will SSH into a running Vagrant machine and give you access to a shell.

If a `--` (two hyphens) are found on the command line, any arguments after
this are passed directly into the `ssh` executable. This allows you to pass
any arbitrary commands to do things such as reverse tunneling down into the
`ssh` program.

## Options

* `-c COMMAND` or `--command COMMAND` - This executes a single SSH command, prints
  out the stdout and stderr, and exits.

* `-p` or `--plain` - This does an SSH without authentication, leaving
  authentication up to the user.

## Background Execution

If the command you specify runs in the background (such as appending a `&` to
a shell command), it will be terminated almost immediately. This is because
when Vagrant executes the command, it executes it within the context of a
shell, and when the shell exits, all of the child processes also exit.

To avoid this, you will need to detach the process from the shell. Please
Google to learn how to do this for your shell. One method of doing this is
the `nohup` command.
