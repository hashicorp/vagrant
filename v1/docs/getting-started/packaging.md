---
layout: getting_started
title: Getting Started - Packaging

current: Packaging
previous: Port Forwarding
previous_url: /v1/docs/getting-started/ports.html
next: Teardown
next_url: /v1/docs/getting-started/teardown.html
---
# Packaging

With the virtual machine working and ready, we're ready to get to work.
But let's assume in this situation that you have other team members, and
you want to share the same virtual environment with them. Let's package this
new environment into a box for them so they can get up and running
with just a few keystrokes.

Packages are exported images of your current virtual environment which
can be easily distributed. They're typically suffixed with a "box" extension,
hence they are known as box files. Optionally, Vagrantfiles can be included
with boxes, which can be used to specify forwarded ports, shared folders, etc.

Before working through the rest of this page, make sure the virtual environment
is built by running `vagrant up`.

## Creating the Vagrantfile

First, we're going to create a basic Vagrantfile we'll package with the
box which will forward the web port. This way, users of the box can simply
add the box, do a `vagrant up`, and have everything working, including HTTP!
Create a new file, which will be the file used as the Vagrantfile for the
box. Name the file `Vagrantfile.pkg` and put the following contents in it:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # Forward apache
  config.vm.forward_port 80, 8080
end
{% endhighlight %}

<div class="info">
  <h3>What's with the MAC address?</h3>
  <p>
    When an OS is installed, it typically sets up the MAC address associated
    with the <code>eth0</code> network interface, which allows the VM to connect to the
    internet. But when importing a base, VirtualBox changes the MAC address
    to something new, which breaks <code>eth0</code>. The MAC address of the base must
    be persisted in the box Vagrantfile so that Vagrant can setup the MAC address
    to ensure internet connectivity.
  </p>
</div>

## Packaging the Project

Run the following code to package the environment up:

{% highlight bash %}
$ vagrant package --vagrantfile Vagrantfile.pkg
{% endhighlight %}

`vagrant package` takes the virtual environment from the current project
and packages it into a `package.box` file in the same directory. The
`--vagrantfile` option tells `vagrant package` to include the port
forwarding lines in `Vagrantfile.pkg` inside the box, so that VMs
created using the box will automatically have port forwarding configured
for them, without the user having to edit their VM's `Vagrantfile`
(Boxes have their own `Vagrantfile` -- for more details on how this
works, see the [documentation for
Vagrantfiles](http://vagrantup.com/v1/docs/vagrantfile.html)).

## Distributing the Box

Vagrant currently supports installing boxes from local file path or from
HTTP. If the box you're distributing has private data on it (such as a
company's web application or client work for freelancers), then you should
keep the box on a secure filesystem where the public cannot access it.

If the box you're distributing is meant to be public, HTTP is the best
resource to upload to, so that anyone can easily download it.

Once the box is in place, other developers can add it and use it just
like any other box. The example below is from the point of view of a new
developer on your team using your newly packaged box:

{% highlight bash %}
$ vagrant box add my_box /path/to/the/package.box
$ vagrant init my_box
$ vagrant up
{% endhighlight %}

At this point, they should have a fully functional environment which exactly
mirrors the environment set up in previous steps of the guide. Notice that
they didn't have to do do provisioning, or set up anything on their system
(other than Vagrant), etc. Distributing development environments has never
been so easy.
