---
page_title: "Providers - Getting Started"
sidebar_current: "gettingstarted-providers"
---

# Providers

In this getting started guide, your project was always backed with
[VirtualBox](http://www.virtualbox.org). But Vagrant can work with
a wide variety of backend providers, such as [VMware](/v2/vmware/index.html),
[AWS](http://github.com/mitchellh/vagrant-aws), and more. Read the page
of each provider for more information on how to set them up.

Once you have a provider installed, you don't need to make any modifications
to your Vagrantfile, just `vagrant up` with the proper provider and
Vagrant will do the rest:

```
$ vagrant up --provider=vmware_fusion
...
```

Ready to move that to the cloud? Take it to AWS:

```
$ vagrant up --provider=aws
...
```

Once you run `vagrant up` with another provider, every other Vagrant
command doesn't need to be told what provider to use. Vagrant can automatically
figure it out. So when you're ready to SSH or destroy or anything else,
just run the commands like normal, such as `vagrant destroy`. No extra
flags necessary.

For more information on providers, read the full documentation on
[providers](/v2/providers/index.html).

<a href="/v2/getting-started/rebuild.html" class="button inline-button prev-button">Rebuild</a>
