---
layout: getting_started
title: Getting Started - Setting up Windows
---
# Windows

## Install Ruby and Vagrant

The first step is to get Ruby and RubyGems running on Windows.
We recommend [RubyInstaller](http://rubyinstaller.org/) for a quick one-click
solution, and this is the solution we support. There are, however,
[other methods](http://www.ruby-lang.org/en/downloads/) to getting
Ruby running on windows.

Once Ruby and RubyGems are installed, install Vagrant with a single command:

{% highlight bash %}
C:\> gem install vagrant
{% endhighlight %}

Finally, as with other platforms, you will need to have downloaded
and installed [Oracle's Virtualbox](http://www.virtualbox.org/)
for Vagrant to run properly. Vagrant will verify this when it is first run.


<div class="alert alert-block alert-notice">
  <h3>Issues with 'ffi' gem installing on windows</h3>
  <p>
    If you are having trouble installing the ffi gem on windows, try using
    version '1.0.9'.  New versions of the gem have trouble installing on
    Windows even with DevKit installed, and this version seems to work well
    with vagrant and compiles correctly.
  </p>
</div>

## Good to go!

With Vagrant installed, you can now follow the remainder of the
[getting started guide](/docs/getting-started/index.html)
just like any other Vagrant user and everything should work the same across all
operating systems, including Windows.
