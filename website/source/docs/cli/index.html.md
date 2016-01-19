---
layout: "docs"
page_title: "Command-Line Interface"
sidebar_current: "cli"
description: |-
  Almost all interaction with Vagrant is done via the command-line interface.
---

# Command-Line Interface

Almost all interaction with Vagrant is done through the command-line
interface.

The interface is available using the `vagrant` command, and comes installed
with Vagrant automatically. The `vagrant` command in turn has many subcommands,
such as `vagrant up`, `vagrant destroy`, etc.

If you run `vagrant` by itself, help will be displayed showing all available
subcommands. In addition to this, you can run any Vagrant command with the
`-h` flag to output help about that specific command. For example, try
running `vagrant init -h`. The help will output a one sentence synopsis of
what the command does as well as a list of all the flags the command
accepts.

In depth documentation and use cases of various Vagrant commands is
available by reading the appropriate sub-section available in the left
navigational area of this site.

You may also wish to consult the
[documentation](/docs/other/environmental-variables.html) regarding the
environmental variables that can be used to configure and control
Vagrant in a global way.
