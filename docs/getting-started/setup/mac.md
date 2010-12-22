---
layout: getting_started
title: Getting Started - Setting up Mac OS X
---
# Mac OS X

## Built-in

Mac OS X actually comes with Ruby and RubyGems built straight into the
operating system already. These installations will work just fine with
Vagrant if you want the "quick and easy setup." The only step is to make
sure you update your RubyGems installation:

{% highlight bash %}
$ sudo gem update --system
{% endhighlight %}

This is necessary since some gems which Vagrant depends on depend on an
up-to-date RubyGems. Now just head back to the [getting started overview page](/docs/getting-started/index.html)
and continue with the guide!

## MacPorts

Generally, Ruby developers in general prefer to use [MacPorts](http://www.macports.org/) to install
a more up-to-date and unmodified version of Ruby and RubyGems rather
than relying on the stock OS X install.

First, install [MacPorts](http://www.macports.org/) which is a simple
`dmg` file which is downloaded from their site. Be sure to follow their
instructions on setting up the `PATH` variable, if necessary (the installer
actually automatically does this on the more recent versions of MacPorts).

Next, install Ruby and RubyGems with a single command:

{% highlight bash %}
$ sudo port install ruby rb-rubygems
{% endhighlight %}

And you'll probably want to update your RubyGems installation, since
MacPorts's is often out of date:

{% highlight bash %}
$ sudo gem update --system
{% endhighlight %}

And now your system is prepped and ready to go.
