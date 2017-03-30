---
layout: "intro"
page_title: "Providers - Getting Started"
sidebar_current: "gettingstarted-providers"
description: |-
  In this getting started guide, your project was always backed with VirtualBox.
  But Vagrant can work with a wide variety of backend providers, such as VMware,
  AWS, and more. Read the page of each provider for more information on how to
  set them up.
---

# Providers

In this getting started guide, your project was always backed with
[VirtualBox](https://www.virtualbox.org). But Vagrant can work with
a wide variety of backend providers, such as [VMware](/docs/vmware/),
[AWS](https://github.com/mitchellh/vagrant-aws), and more. Read the page
of each provider for more information on how to set them up.

Once you have a provider installed, you do not need to make any modifications
to your Vagrantfile, just `vagrant up` with the proper provider and
Vagrant will do the rest:

```
$ vagrant up --provider=vmware_fusion
```

Ready to move that to the cloud? Take it to AWS:

```
$ vagrant up --provider=aws
```

Once you run `vagrant up` with another provider, every other Vagrant
command does not need to be told what provider to use. Vagrant can automatically
figure it out. So when you are ready to SSH or destroy or anything else,
just run the commands like normal, such as `vagrant destroy`. No extra
flags necessary.

For more information on providers, read the full documentation on
[providers](/docs/providers/).

## Next Steps

That's it! You have successfully completed the getting started guide for Vagrant.
Here are some interesting topics you might find relevant:

- [Configuring VirtualBox settings](/docs/virtualbox/)
- [Working with Plugins](/docs/plugins/)
- [Customizing Synced Folders](/docs/synced-folders/)
- [Provisioning with Puppet, Chef, or Ansible](/docs/provisioning/)
