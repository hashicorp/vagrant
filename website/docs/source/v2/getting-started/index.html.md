---
page_title: "Getting Started"
sidebar_current: "gettingstarted"
---

# Getting Started

The Vagrant getting started guide will walk you through your first
Vagrant project, and show off the basics of the major features Vagrant
has to offer.

If you're curious what benefits Vagrant has to offer, you
should also read the ["Why Vagrant?"](/v2/why-vagrant/index.html) page.

The getting started guide will use Vagrant with [VirtualBox](http://www.virtualbox.org),
since it is free, available on every major platform, and built-in to
Vagrant. After reading the guide though, don't forget that Vagrant
can work with [many other providers](/v2/getting-started/providers.html).

Before diving into your first project, please [install the latest version of Vagrant](/v2/installation/index.html).
And because we'll be using [VirtualBox](http://www.virtualbox.org) as our
provider for the getting started guide, please install that as well.

<div class="alert alert-block alert-info">
<p>
<strong>More of a book person?</strong> If you prefer to read a physical
book, you may be interested in
<a href="http://www.amazon.com/gp/product/1449335837/ref=as_li_qf_sp_asin_il_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=1449335837&linkCode=as2&tag=vagrant-20">
Vagrant: Up and Running
</a>, written by the author of Vagrant and published by O'Reilly.
</p>
</div>

## Up and Running

```
$ vagrant init hashicorp/precise32
$ vagrant up
```

After running the above two commands, you'll have a fully running
virtual machine in [VirtualBox](https://www.virtualbox.org) running
Ubuntu 12.04 LTS 32-bit. You can SSH into this machine with
`vagrant ssh`, and when you're done playing around, you can remove
all traces of it with `vagrant destroy`.

Now imagine every project you've ever worked on being this easy to
set up.

With Vagrant, `vagrant up` is all you need to work on any project,
to install every dependency that project needs, and to set up any
networking and synced folders so you can continue working from the
comfort of your own machine.

The rest of this guide will walk you through setting up a more
complete project, covering more features of Vagrant.

<a href="/v2/getting-started/project_setup.html" class="button inline-button next-button">Project Setup</a>
