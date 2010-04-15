---
layout: getting_started
title: Getting Started - Setting up Ubuntu
---
# Ubuntu

## Installing Ruby and RubyGems

The easiest way to install Ruby and RubyGems is via Ubuntu's built
in package manager:

{% highlight bash %}
$ sudo apt-get install
{% endhighlight %}

You'll also want to verify that RubyGems is fully updated, since the
packages can often get out of date:

{% highlight bash %}
$ sudo gem update --system
{% endhighlight %}

## VirtualBox OSE

By default, VirtualBox installed via Ubuntu's package repositories
will be "VirtualBox Open Source Edition (OSE)." While Vagrant will work
fine with this edition (as long as its version 3.1 or higher), there
are some additional configuration steps necessary within the Vagrantfile.
VirtualBox OSE doesn't support headless VMs, so you must always boot
into a GUI:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # Add this anywhere in your Vagrantfile
  config.vm.boot_mode = "gui"
end
{% endhighlight %}

<div class="info">
  <h3>Vagrantfile?</h3>
  <p>
    Not sure what a Vagrantfile is? Don't worry! The getting started guide
    will get to it. If you're not at that point in the guide yet, just put
    this page in a background tab and remember to come back and check on it
    when you cover Vagrantfiles.
  </p>
</div>