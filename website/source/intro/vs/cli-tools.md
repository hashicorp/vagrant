---
layout: "intro"
page_title: "Vagrant vs. CLI Tools"
sidebar_current: "vs-cli-tools"
description: |-
  Virtualization software like VirtualBox and VMware come with command line
  utilities for managing the lifecycle of machines on their platform. Vagrant
  actually uses many of these utilities internally. The difference between these
  CLI tools and Vagrant is that Vagrant provides a declarative, reproducible,
  idempotent workflow.
---

# Vagrant vs. CLI Tools

Virtualization software like VirtualBox and VMware come with command line
utilities for managing the lifecycle of machines on their platform. Many
people make use of these utilities to write their own automation. Vagrant
actually uses many of these utilities internally.

The difference between these CLI tools and Vagrant is that Vagrant builds
on top of these utilities in a number of ways while still providing a
consistent workflow. Vagrant supports multiple synced folder types, multiple
provisioners to setup the machine, automatic SSH setup, creating HTTP tunnels
into your development environment, and more. All of these can be configured
using a single simple configuration file.

Vagrant still has a number of improvements over manual scripting even if you
ignore all the higher-level features Vagrant provides. The command-line
utilities provided by virtualization software often change each version
or have subtle bugs with workarounds. Vagrant automatically detects the
version, uses the correct flags, and can work around known issues. So if
you're using one version of VirtualBox and a co-worker is using a different
version, Vagrant will still work consistently.

For highly-specific workflows that don't change often, it can still be
beneficial to maintain custom scripts. Vagrant is targeted at building
development environments but some advanced users still use the CLI tools
underneath to do other manual things.
