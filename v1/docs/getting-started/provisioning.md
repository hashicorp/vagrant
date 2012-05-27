---
layout: getting_started
title: Getting Started - Provisioning

current: Provisioning
previous: SSH
previous_url: /docs/getting-started/ssh.html
next: Port Forwarding
next_url: /docs/getting-started/ports.html
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
using [chef](http://www.opscode.com/chef), either [chef solo](http://wiki.opscode.com/display/chef/Chef+Solo)
and [chef server](http://wiki.opscode.com/display/chef/Chef+Server), or [Puppet](http://www.puppetlabs.com/puppet) or
you can also [extend vagrant](/docs/provisioners/others.html) to support more provisioners, but this is an advanced topic
which we won't cover here.

For our basic HTML website, we're going to show you how to use both Chef or Puppet provisioning to setup Apache
to serve the website. Note that you should choose which you want to try (either Chef or Puppet),
or try both, but be sure to `destroy` and `up` your VM in between tries
so you start with a clean slate.

## Configuring Chef and the Vagrant

Since a tutorial on how to use Chef is out of scope for this getting started
guide, I've prepackaged the cookbooks for you for provisioning. You just have
to configure your Vagrantfile to point to them:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.box = "lucid32"

  # Enable and configure the chef solo provisioner
  config.vm.provision :chef_solo do |chef|
    # We're going to download our cookbooks from the web
    chef.recipe_url = "http://files.vagrantup.com/getting_started/cookbooks.tar.gz"

    # Tell chef what recipe to run. In this case, the `vagrant_main` recipe
    # does all the magic.
    chef.add_recipe("vagrant_main")
  end
end
{% endhighlight %}

Note that while we use a URL to download the cookbooks for this getting
started project, you can also put cookbooks in a local directory, which is
nice for storing your cookbooks in version control with your project. More
details on this can be found in the [chef solo documentation](/docs/provisioners/chef_solo.html).

## Configuring Puppet and the Vagrant

Alternatively, you can use Puppet to configure Apache.  To do this we create
a directory called `manifests` (in the root where your Vagrantfile is located)
and create a file to hold our Puppet configuration, for example `default.pp`.

Note both the path and file name are configurable but Vagrant will default
to `manifests/default.pp`.

The manifest file will contain the required Puppet configuration, for example:

{% highlight ruby %}
# Basic Puppet Apache manifest

class apache {
  exec { 'apt-get update':
    command => '/usr/bin/apt-get update'
  }

  package { "apache2":
    ensure => present,
  }

  service { "apache2":
    ensure => running,
    require => Package["apache2"],
  }
}

include apache
{% endhighlight %}

We then add support in the Vagrantfile to support Puppet provisioning:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.box = "lucid32"

  # Enable the Puppet provisioner
  config.vm.provision :puppet
end
{% endhighlight %}

Alternatively you can run Puppet in client-server mode by enabling the `:puppet_server` provisioner.  See the [Puppet Server](/docs/provisioners/puppet_server.html) documentation for more details.

**Note:** The Puppet example above is not quite equivalent to the Chef example,
Apache isn't properly configured to serve our `/vagrant` directory. The main
purpose here is to show you how Puppet provisioning works with Vagrant. You
can imagine how you would configure Apache further to serve from the `/vagrant`
directory.

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

This works because the scripts for the provisioners above were written to
modify the `DocumentRoot` for Apache to point to your `/vagrant` directory.
The exact details of how this was done is specific to each provisioner and
out of scope for the purpose of this getting started guide. For more
information, I recommend looking into Chef or Puppet.

In the next step of the getting started guide, we'll show you how to view
your website using your own browser.
