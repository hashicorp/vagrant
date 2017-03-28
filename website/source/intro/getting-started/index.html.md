---
layout: "intro"
page_title: "Getting Started"
sidebar_current: "gettingstarted"
description: |-
  The Vagrant getting started guide will walk you through your first
  Vagrant project, and show off the basics of the major features Vagrant
  has to offer.
---

# Getting Started

The Vagrant getting started guide will walk you through your first
Vagrant project, and show off the basics of the major features Vagrant
has to offer.

If you are curious what benefits Vagrant has to offer, you
should also read the ["Why Vagrant?"](/intro/index.html) page.

The getting started guide will use Vagrant with [VirtualBox](https://www.virtualbox.org),
since it is free, available on every major platform, and built-in to
Vagrant. After reading the guide though, do not forget that Vagrant
can work with [many other providers](/intro/getting-started/providers.html).

Before diving into your first project, please [install the latest version of Vagrant](/docs/installation/).
And because we will be using [VirtualBox](https://www.virtualbox.org) as our
provider for the getting started guide, please install that as well.

<div class="alert alert-block alert-info">
  <strong>More of a book person?</strong> If you prefer to read a physical
  book, you may be interested in
  <a href="https://www.amazon.com/gp/product/1449335837/ref=as_li_qf_sp_asin_il_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=1449335837&linkCode=as2&tag=vagrant-20" class="alert-link">
  Vagrant: Up and Running</a>, written by the author of Vagrant and published by O'Reilly.
</div>

## Up and Running

```
$ vagrant init hashicorp/precise64
$ vagrant up
```

After running the above two commands, you will have a fully running
virtual machine in [VirtualBox](https://www.virtualbox.org) running
Ubuntu 12.04 LTS 64-bit. You can SSH into this machine with
`vagrant ssh`, and when you are done playing around, you can terminate the
virtual machine with `vagrant destroy`.

Now imagine every project you've ever worked on being this easy to
set up! With Vagrant, `vagrant up` is all you need to work on any project,
to install every dependency that project needs, and to set up any
networking or synced folders, so you can continue working from the
comfort of your own machine.

The rest of this guide will walk you through setting up a more
complete project, covering more features of Vagrant.

## Next Steps

You have just created your first virtual environment with Vagrant. Read on to
learn more about [project setup](/intro/getting-started/project_setup.html).
