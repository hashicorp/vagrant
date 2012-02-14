---
layout: documentation
title: Documentation - Provisioners

current: Provisioners
---
# Provisioners

Launching a blank virtual machine is not very useful, so Vagrant supports provisioning
virtual machines through the use of _provisioners_. There are a handful of provisioners
for the most common choices supported out of the box with Vagrant, but it is also
possible to add your own very easily as long as you know a little Ruby.

Provisioners allow you to easily setup your virtual machine with everything it
needs to run your software. Of course, provisioning is completely option. If you
want to install all the software on your virtual machine by hand, then that is your
choice. But provisioning is an important part of making virtual machine creation
repeatable, and the scripts made for provisioning can typically be used to setup
production machines quickly as well.

Before diving directly into the specific provisioner you want to use, it is recommended
that you read the rest of this page for a general introduction to provisioners, since
their general usage is similar.

The available provisioners that come standard with Vagrant are:

<ul>
	<li><a href="/docs/provisioners/chef_solo.html">Chef Solo</a></li>
	<li><a href="/docs/provisioners/chef_server.html">Chef Server</a></li>
	<li><a href="/docs/provisioners/puppet.html">Puppet Standalone</a></li>
	<li><a href="/docs/provisioners/puppet_server.html">Puppet Server</a></li>
	<li><a href="/docs/provisioners/shell.html">Shell</a></li>
</ul>

<br />

## Which Provisioner Should I Use?

Ah, with the freedom of choice comes the complication of choosing
what is right for you. However, if you're asking this question, then almost
certainly the best choice for you to get started is the **shell** provisioner.
This provisioner lets you run a shell script with root privileges within your
virtual machine. It doesn't get any simpler than that!

However, once you start outgrowing basic shell scripts and plan on installing
software across multiple machines, especially in production, you should learn
[Chef](http://opscode.com/chef) or [Puppet](http://puppetlabs.com/puppet). Vagrant
is a fantastic learning resource for these two technologies.

## Enabling a Provisioner

The `config.vm.provision` method is used to enable provisioners. Each provisioner
has a unique identifier which can be found on the respective documentation page of
the provisioner. Chef solo, for example, is `:chef_solo`. This identifier is used
to enable provisioning:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo
end
{% endhighlight %}

All provisioners, however, require a bit more configuration than simply enabling
them. Luckily, configuring a provisioner is easy as well. The exact configuration
options for a provisioner are documented on their respective pages, but configuration
follows the same format for each.

For basic key-value options, you can simply append a hash when enabling the provisioner,
where the keys of the has are the configuration keys, and the values of course are
the values for that key. Example:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo, :cookbooks_path => "cookbooks"
end
{% endhighlight %}

Most of the time, it looks nicer to use a slightly longer form. Additionally, if the
provisioner provides convenience methods (more than basic key-value options), then
you must use this longer form. Another example:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "cookbooks"
    chef.add_recipe "apache"
  end
end
{% endhighlight %}

The specific Ruby construct in use here is called a "block" and can be thought of
as passing a callback to the `provision` configuration method. This callback is
called with an object used to configure that specific provisioner.

Both methods to configuring a provisioner have their pros and cons, but are
otherwise used to achieve the same things, so use whichever you feel most
comfortable with.

## Running a Provisioner

Provisioning is automatically run during calls to `vagrant up` and `vagrant reload`.
But since those methods do a lot more than just provision, Vagrant also provides
the `vagrant provision` command which you can call on an already running virtual
machine to just run the provisioner.

Note that in some cases you may be forced to run `reload` so a provisioner can
setup shared folders or some other meta-data that requires the virtual machine
to be powered off, but Vagrant should properly notify you in these cases.
