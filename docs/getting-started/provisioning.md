---
layout: getting_started
title: Getting Started - Provisioning
---
# Provisioning

Boxes aren't always going to be one-step setups for your Vagrant environment.
Often times boxes will be used as a base for a more complicated setup. For
example: Perhaps you're creating a rails application which also uses AMQP and
some custom background worker daemons. In this situation, it would be easiest
to use the rails box, but then add the custom software on top of it (and
perhaps even packaging it later so others can make use of it).

Luckily, Vagrant comes with provisioning built right into the software by
using [chef](http://www.opscode.com/chef).

For our basic rails app, we're going to use provisioning for a different
purpose: installing some basic system monitoring tools, specifically [htop](http://htop.sourceforge.net/).
The getting started guide doesn't cover more advanced cookbooks for the purpose of keeping things
simple, but anything is possible with chef.

## Creating the `htop` Cookbook

First things first, we're going to create a directory to store our cookbooks
and then we're going to create the directories for the `htop` cookbook.

{% highlight bash %}
$ mkdir -p cookbooks/htop/recipes
{% endhighlight %}

**Note:** Generally, cookbooks are created with Rake commands using the Rakefile
provided by the Opscode cookbooks repository. Since what we're doing here is so
simple, we're not using this, but most projects typically do.

In the recipes directory of the `htop` cookbook, create a file named `default.rb`
with the following contents. This file defines how chef installs `htop`. The file
should be at `cookbooks/htop/recipes/default.rb`.

{% highlight ruby %}
# Install the htop package via the packaging system
package "htop" do
  action :install
end
{% endhighlight %}

## Creating the `vagrant_main` Cookbook

Vagrant uses `vagrant_main` as the entry-point cookbook for chef. This is
analogous to a C program calling `int main` to start a program. The actual
contents of the `vagrant_main` recipe should be to simply include other recipes
in the order you want them ran. First, we'll setup the directory for this cookbook:

{% highlight bash %}
$ mkdir -p cookbooks/vagrant_main/recipes
{% endhighlight %}

And then the contents of the `default.rb` file:

{% highlight ruby %}
# Just install htop
require_recipe "htop"
{% endhighlight %}

**Note:** The fact that Vagrant calls `vagrant_main` as the main cookbook is
configurable using the Vagrantfile, but we won't modify it in this getting
started guide.

## Enabling Provisioning

With everything is now in place, the final step is to modify the Vagrantfile
to point to our cookbooks directory and to enable provisioning. Add the
following contents to the project's Vagrantfile:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.chef.enabled = true

  # This directory is expanded relative to the project directory.
  config.chef.cookbooks_path = "cookbooks"
end
{% endhighlight %}

**Note:** If you're feeling lazy, you can simply copy and paste the above code
at the end of the Vagrantfile after the previous configuration block. Vagrant
runs all configuration blocks, overwriting the newest values over the older
values. Otherwise, you may simply copy the block contents and append it to the
block contents of your current Vagrantfile. Either way, things will work.

## Running it!

With everything setup, you can now test what we have so far. If you haven't yet
created the vagrant environment, run `vagrant up` to create it from scratch.
Otherwise, if you already ran `vagrant up` and chose to suspend or shut down
the environment during the last step, or even if its still running,
run `vagrant reload` to simply reload the environment, but not
create a new one.

If you have no idea what's going on, run a `vagrant down` to
tear down any potentially created vagrant environment, and start over with
a fresh `vagrant up`.

You should notice that provisioning is now part of the steps executed, and
Vagrant will even log and output the output of chef, so you can debug any
problems which may occur.

You can verify everything worked successfully by SSHing in to the running
environment and trying to execute `htop`:

{% highlight bash %}
$ vagrant ssh
...
vagrant-instance ~$ htop
...
{% endhighlight %}