---
layout: documentation
title: Documentation - Provisioners - Chef Solo (Remote)
---
# Chef Solo Provisioning (Remote)

**Before reading this page, be sure to read the [chef solo provisioning](/docs/provisioners/chef_solo.html).**

[Chef Solo](http://wiki.opscode.com/display/chef/Chef+Solo) also allows for an additional option
of downloading packaged (`tar.gz`) cookbooks from a remote URL to provision. This is a bit more
complicated than using a local cookbooks path (covered in the chef solo provisioning documentation),
but is less complicated than setting up a full blown chef server.

Prior to reading this page, it is recommend that you spend a few minutes reading about
[running chef solo from a URL](http://wiki.opscode.com/display/chef/Chef+Solo#ChefSolo-RunningfromaURL).
This will allow you to familiarize yourself with the terms used throughout the rest of
this page.

## Setting the Recipe URL

The first step is specify the recipe URL in the Vagrantfile. This is the URL from
which chef solo will download the cookbooks. The Vagrantfile below shows how this is
done:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provisioner = :chef_solo
  config.chef.recipe_url = "http://files.vagrantup.com/getting_started/cookbooks.tar.gz"
end
{% endhighlight %}

## Setting the Cookbooks Path

Next, you must specify the paths within the downloaded package where the cookbooks
are. By default, Vagrant assumes they're in a top-level "cookbooks" directory within
the package, but sometimes you may include other directories, such as "site-cookbooks"
which you must manually specify.

To tell Vagrant what the cookbook path is, you use the same `config.chef.cookbooks_path`
setting, but with a little extra formatting to let Vagrant know you're describing a
path on the VM, and not on the host machine.

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.chef.cookbooks_path = [:vm, "cookbooks"]
end
{% endhighlight %}

You may also use an array to specify multiple cookbook paths.

<div class="info">
  <h3>Mixing Host and VM Cookbook Paths</h3>
  <p>
    You can also mix together host and VM cookbook paths. This allows
    you to use some cookbooks from a remote location, and some from a
    local directory. An example of this is shown below:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.chef.cookbooks_path = ["local-cookbooks", [:vm, "cookbooks"]]
end
{% endhighlight %}
  </p>
</div>

## Enabling and Executing

Now that everything is setup, provisioning the VM is the same as always: if you're
building the VM from scratch, just run `vagrant up`. Otherwise, run `vagrant reload`
to simply restart the VM, provisioning in the process.
