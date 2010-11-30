---
layout: default
title: FAQ
---

<h1 class="top">FAQ</h1>

### Why should I use Vagrant? What I'm doing now works just fine.

One could say that web development was working just fine prior to
the rise of MVC and opinionated development frameworks and they would
be speaking the truth as well. Vagrant is not trying to change the way
you work because its wrong, per se, but move web development forward
by providing isolated environments which are easy to build, portable,
and lightweight. For more specific reasons, check out the "[Why Vagrant?](/docs/getting-started/why.html)" page.

### Could you perhaps convert a Vagrant project into an EC2 instance for deployment?

That's where provisioners comes in. Vagrant can use [Chef](http://www.opscode.com/chef) or 
[Puppet](http://www.puppetlabs.com/puppet) for provisioning VMs. 

Both tools provide software configuration management -- you write manifests that specify 
how a system should be set up. If you write your Chef or Puppet configuration the right way 
you can take the same set of configuration you write and deploy to EC2 or any other Linux box, virtual or not.
So with Vagrant you can essentially pass around a virtual machine configuration amongst
your team and be confident that the entire team is coding and testing in a near-exact
replica of the production environment. Then when you're ready to deploy to production,
you should be able to share the same configuration and set up the same environment
for production as well.

### Vagrant would be so much better if it had feature `X`!

Vagrant is open source and released under a permissive [license](/license.html),
so feel free to modify it and add the feature! Open up a ticket
explaining why the feature adds value to Vagrant with a link to the
patch you'd like us to merge in and we probably will. If you aren't comfortable
adding the feature yourself, still make a ticket and if its compelling
enough, someone will add it in for you.

### Don't virtual machines slow down your main development machine?

The short answer: no. Longer answer: Given a big enough and busy enough virtual machine... perhaps. But through real-world
usage, we've found that most virtual machines are small, using 256 to 500 MB or RAM,
and typically are running mostly idle processes. Its not as if the virtual machines
are running 3D games (although I suppose you could try it)!

### Virtual machines take up way too much hard drive space!

An average virtual machine that Vagrant provisions is about 500 MB of physical
disk space total (although the virtual drive had a capacity
of 40 GB). Sure, if you have 10 vagrant projects with their virtual environments built,
this is 5 GB, but its still only 5 GB. And don't forget that Vagrant allows you to complete
tear down the environment and rebuild it in a flash, so you shouldn't ever even need all
those environments built at the same time. Just run `vagrant up` when you need a virtual
machine and disk space will be kept low.
