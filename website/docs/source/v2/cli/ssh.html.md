---
page_title: "vagrant ssh - Command-Line Interface"
sidebar_current: "cli-ssh"
---

# SSH

**Command: `vagrant ssh`**

This will SSH into a running Vagrant machine and give you access to a shell.

If a `--` (two hyphens) are found on the command line, any arguments after
this are passed directly into the `ssh` executable. This allows you to pass
any arbitrary commands to do things such as reverse tunneling down into the
`ssh` program.

## Options

* `-c COMMAND` or `--command COMMAND` - This executes a single SSH command, prints
  out the stdout and stderr, and exits. stdin will not be functional on this
  executed command.

* `-p` or `--plain` - This does an SSH without authentication, leaving
  authentication up to the user.
