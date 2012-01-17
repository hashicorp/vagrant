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
