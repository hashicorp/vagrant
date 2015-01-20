---
page_title: "Project Setup - Getting Started"
sidebar_current: "gettingstarted-projectsetup"
---

# Project Setup

The first step for any project to use Vagrant is to configure Vagrant
using a [Vagrantfile](/v2/vagrantfile/index.html). The purpose of the
Vagrantfile is twofold:

1. Mark the root directory of your project. A lot of the configuration
  of Vagrant is relative to this root directory.

2. Describe the kind of machine and resources you need to run your project,
  as well as what software to install and how you want to access it.

Vagrant has a built-in command for initializing a directory for usage
with Vagrant: `vagrant init`. For the purpose of this getting started guide,
please follow along in your terminal:

```
$ mkdir vagrant_getting_started
$ cd vagrant_getting_started
$ vagrant init
```

This will place a `Vagrantfile` in your current directory. You can
take a look at the Vagrantfile if you want, it is filled with comments
and examples. Don't be afraid if it looks intimidating, we'll modify it
soon enough.

You can also run `vagrant init` in a pre-existing directory to
set up Vagrant for an existing project.

The Vagrantfile is meant to be committed to version control with
your project, if you use version control. This way, every person working
with that project can benefit from Vagrant without any upfront work.

<a href="/v2/getting-started/index.html" class="button inline-button prev-button">Getting Started</a>
<a href="/v2/getting-started/boxes.html" class="button inline-button next-button">Boxes</a>
