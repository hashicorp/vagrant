---
layout: getting_started
title: Getting Started - Provisioning
---
# Provisioning

Boxes aren't always going to be one-step setups for your Vagrant environment.
Often times boxes will be used as a base for a more complicated setup. For
example: Perhaps you're creating a web application which also uses AMQP and
some custom background worker daemons. In this situation, it would be easiest
to use the base box, but then add the custom software on top of it (and then
packaging it so others can more easily make use of it, but we'll cover this
later).

Luckily, Vagrant comes with provisioning built right into the software by
using [chef](http://www.opscode.com/chef), with support for both [chef solo](http://wiki.opscode.com/display/chef/Chef+Solo)
and [chef server](http://wiki.opscode.com/display/chef/Chef+Server). You can
also [extend vagrant](/docs/provisioners/others.html) to support more provisioners, but this is an advanced topic
which we won't cover here.

For our basic HTML website, we're going to use chef provisioning to setup Apache
to serve the website.

## Configuring Chef and the Vagrant

Since a tutorial on how to use Chef is out of scope for this getting started
guide, I've prepackaged the cookbooks for you for provisioning. You just have
to configure your Vagrantfile to point to them:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.box = "lucid32"

  # Enable the chef solo provisioner
  config.vm.provisioner = :chef_solo

  # Grab the cookbooks from the Vagrant files
  config.chef.recipe_url = "http://files.vagrantup.com/getting_started/cookbooks.tar.gz"

  # Tell chef what recipe to run. In this case, the `vagrant_main` recipe
  # does all the magic.
  config.chef.add_recipe("vagrant_main")
end
{% endhighlight %}

Note that while we use a URL to download the cookbooks for this getting
started project, you can also put cookbooks in a local directory, which is
nice for storing your cookbooks in version control with your project. More
details on this can be found in the [chef solo documentation](/docs/provisioners/chef_solo.html).

## Running it!

With provisioning configured, just run `vagrant up` to create your environment
and Vagrant will automatically provision it. If your environment is already
running since you did an `up` in a previous step, just run `vagrant reload`,
which will quickly restart your VM, skipping the import step.

After Vagrant completes running, the web server will be up and running as well.
You can't see your website from your own browser yet, since we haven't covered
port forwarding, but you can verify that the provisioning works by SSHing into
the VM and checking the output of hitting `127.0.0.1`:

{% highlight bash %}
$ vagrant ssh
...
vagrant@vagrantup:~$ wget -qO- 127.0.0.1
<h1>Hello from a Vagrant VM</h1>
vagrant@vagrantup:~$
{% endhighlight %}

In the next step of the getting started guide, we'll show you how to view
your website using your own browser.

[&larr; SSH](/docs/getting-started/ssh.html) &middot; Provisioning &middot; [Port Forwarding &rarr;](/docs/getting-started/ports.html)
