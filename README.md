# Vagrant

* Website: [https://www.vagrantup.com/](https://www.vagrantup.com/)
* Source: [https://github.com/mitchellh/vagrant](https://github.com/mitchellh/vagrant)
* [![Gitter chat](https://badges.gitter.im/mitchellh/vagrant.png)](https://gitter.im/mitchellh/vagrant)
* Mailing list: [Google Groups](https://groups.google.com/group/vagrant-up)

## Why Vagrant? 
 
Nowadays web development gets more complex than ever and the same is with the development environment. 
We have to work in group of people, big teams, departments connected over the world. 
Everyone is a member of a project. Everyone need to be able to run and work on the projects. 
Developers are spending countless hours, to build development environments. With everyone in a team working on their own machine, 
with their own development tools on their own operating systems, it´s almost impossible to keep a consistent configuration across all the machines. Specially if you have to work with freelancers or consulting companies. 

## What is Vagrant? 
Vagrant is an impressive development tool, which lets you manage and support the virtualization of your development environment. 
Instead of running the projects local on your computer and the different requirements and all dependencies of every project, 
Vagrant gives the possibility to run each project in its own dedicated virtual environment. 
The next time when you need to go back to a previous project, you don't need to worry about any potential conflicts with changes made to your development environment 
(for example, if you have upgraded PHP, MySQL, or Apache on your local environment, or within the Vagrant environment for another project). 
If you have to bring a new team member on board, they can be up and running in minutes while Vagrant will take care of all the software and services needed to run the project on their machine. 
If you have one project, which uses one web server such as Apache, and another which uses Node, Vagrant lets you run these projects independently. 


Development environments managed by Vagrant can run on local virtualized
platforms such as VirtualBox or VMware, in the cloud via AWS or OpenStack,
or in containers such as with Docker or raw LXC.

Vagrant provides the framework and configuration format to create and
manage complete portable development environments. These development
environments can live on your computer or in the cloud, and are portable
between Windows, Mac OS X, and Linux.

## Quick Start

For the quick-start, we'll bring up a development machine on
[VirtualBox](https://www.virtualbox.org/) because it is free and works
on all major platforms. Vagrant can, however, work with almost any
system such as [OpenStack](https://www.openstack.org/), [VMware](https://www.vmware.com/), [Docker](https://docs.docker.com/), etc.

First, make sure your development machine has
[VirtualBox](https://www.virtualbox.org/)
installed. After this,
[download and install the appropriate Vagrant package for your OS](https://www.vagrantup.com/downloads.html).

To build your first virtual environment:

    vagrant init hashicorp/precise32
    vagrant up

Note: The above `vagrant up` command will also trigger Vagrant to download the
`precise32` box via the specified URL. Vagrant only does this if it detects that
the box doesn't already exist on your system.

## Getting Started Guide

To learn how to build a fully functional development environment, follow the
[getting started guide](https://www.vagrantup.com/docs/getting-started/index.html).

## Installing the Gem from Git

If you want the bleeding edge version of Vagrant, we try to keep master pretty stable
and you're welcome to give it a shot. Please review the installation page [here](https://www.vagrantup.com/docs/installation/source.html).

## Contributing to Vagrant

To install Vagrant from source, please [follow the guide in the Wiki](https://github.com/mitchellh/vagrant/wiki/Installing-Vagrant-from-Source).

You can run the test suite with:

    bundle exec rake

This will run the unit test suite, which should come back all green! Then you're good to go!

If you want to run Vagrant without having to install the gem, you may use `bundle exec`,
like so:

    bundle exec vagrant help

### Acceptance Tests

Vagrant also comes with an acceptance test suite that does black-box
tests of various Vagrant components. Note that these tests are **extremely
slow** because actual VMs are spun up and down. The full test suite can
take hours. Instead, try to run focused component tests.

To run the acceptance test suite, first copy `vagrant-spec.config.example.rb`
to `vagrant-spec.config.rb` and modify it to valid values. The places you
should fill in are clearly marked.

Next, see the components that can be tested:

```
$ rake acceptance:components
cli
provider/virtualbox/basic
...
```

Then, run one of those components:

```
$ rake acceptance:run COMPONENTS="cli"
...
```
