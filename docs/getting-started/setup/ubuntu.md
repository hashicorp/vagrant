---
layout: getting_started
title: Getting Started - Setting up Ubuntu
---
# Ubuntu

## Installing Ruby

The easiest way to install Ruby and RubyGems is via Ubuntu's built
in package manager:

{% highlight bash %}
$ sudo aptitude install ruby1.8-dev ruby1.8 ri1.8 rdoc1.8 irb1.8 libreadline-ruby1.8 libruby1.8 libopenssl-ruby wget
$ sudo ln -s /usr/bin/ruby1.8 /usr/bin/ruby
$ sudo ln -s /usr/bin/ri1.8 /usr/bin/ri
$ sudo ln -s /usr/bin/rdoc1.8 /usr/bin/rdoc
$ sudo ln -s /usr/bin/irb1.8 /usr/bin/irb
{% endhighlight %}

## Installing RubyGems

It is recommended that you install RubyGems from source. All the dependencies
for RubyGems were installed above already so installing from source is
fairly painless:

{% highlight bash %}
$ cd ~
$ wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz
$ tar xvzf rubygems-1.3.7.tgz
$ cd rubygems-1.3.7
$ sudo ruby setup.rb
$ sudo ln -s /usr/bin/gem1.8 /usr/bin/gem
{% endhighlight bash %}

You'll also want to verify that RubyGems is fully updated, since the
packages can often get out of date:

{% highlight bash %}
$ sudo gem update --system
{% endhighlight %}

## VirtualBox OSE

By default, VirtualBox installed via Ubuntu's package repositories
will be "VirtualBox Open Source Edition (OSE)." Vagrant may work with
this edition (as long as the version is currently supported by
Vagrant), but it is not officially supported. It is recommended that you
download the installation package from the [VirtualBox website](http://virtualbox.org)
for the full version.
