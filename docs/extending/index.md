---
layout: extending
title: Extending Vagrant - Overview
---
# Extending Vagrant

While plugins are easy to write and understand, extending Vagrant gets its
own section so that more time could be spent on the details of plugins, to
better guide developers in creating customized Vagrant functionality.

<div class="alert alert-block alert-notice">
  <h3>Plugin API is still growing!</h3>
  <p>
    Plugins are new as of Vagrant 0.6,
    so the API may still have some obvious holes in it. If you find you need
    functionality which isn't directly exposed, please contact us via our
    <a href="/support.html">support lines</a> and we'll work with you to get
    it added.
  </p>
</div>

## Why Extend Vagrant?

Vagrant comes with a ton of features out of the box, and perhaps you've
been satisfied with this. But there are many feature requests out there
which don't make sense for the core of Vagrant (for various reasons), such
as:

* `vagrant rake` - A command to execute the given rake task in the main
  shared folder on the VM.
* `vagrant cookbooks` - A command to manage the chef cookbooks in a Vagrant
  environment.
* Modifying `/etc/hosts` during `vagrant up` to add aliases for host only
  networks.

I don't argue that all of the above features are extremely useful, but
they usually don't fit into Vagrant core, and therefore haven't been
possible before. Using plugins, all of the above can be implemented as
first-class citizens using a supported API.

And who knows, perhaps in the future some of the plugins developers
create will be merged back into Vagrant core!
