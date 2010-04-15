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
will be "VirtualBox Open Source Edition (OSE)." Vagrant may work with
this edition (as long as its version 3.1+), but it is not officially
supported. It is recommended that you download the installation package
from the [VirtualBox website](http://virtualbox.org) for the full version.
