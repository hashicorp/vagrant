---
layout: getting_started
title: Getting Started - Setting up Windows 64-bit
---
# Windows 64-bit

If you're on 64-bit Windows, then the process for installing Ruby and
Vagrant is a bit different, but not any more difficult. The key
ingredients to getting it working are a 64-bit Java runtime and
64-bit JRuby, both of which have automated installers.

## Install Java 64-bit

To install the 64-bit JRE (Java Runtime Environment), follow the
steps below:

1. Go to the [Java SE downloads page](http://www.oracle.com/technetwork/java/javase/downloads/index.html).
2. Click the "Download JRE" button.
3. Select "Windows x64" under the platform dropdown.
4. Check the box saying you agree to the license agreement.
5. Click "Next"
6. Click the link to download the installer (the exe file).
7. Once downloaded, run and complete the installer.

## Install JRuby 64-bit

To install the 64-bit version of JRuby, follow the steps below:

1. Go to the [JRuby downloads page](http://jruby.org/download)
2. Download the latest JRuby Windows Executable for x64.
3. Run and complete the installer. You should check the box which
   asks if you give the installer permission to setup the paths,
   as this will make things easier later.

## Install Vagrant

Once JRuby is installed, everything from this point is pretty normal.
Ruby commands are prefixed with a `j`, which is one of the only differences.

On JRuby, a couple libraries which Vagrant depends on aren't installed
out of the box with JRuby, and must be installed manually. These libraries
are `jruby-openssl` and `jruby-win32ole`:

{% highlight bash %}
$ jgem install jruby-openssl jruby-win32ole
{% endhighlight %}

After this, Vagrant installation proceeds as normal:

{% highlight bash %}
$ jgem install vagrant
{% endhighlight %}

Once this complete, the `vagrant` binary should be available on the
command line.

## Troubleshooting

Is something not working? The most common issue is that JRuby isn't
running on the 64-bit JRE. To verify your Ruby environment is setup
properly, check the version of JRuby and the output should be similar
to what is shown below:

{% highlight bash %}
$ jruby -v
jruby 1.5.6 (ruby 1.8.7 patchlevel 249) (2010-12-03 9cf97c3) (Java HotSpot(TM)
64-Bit Server VM 1.6.0_23) [amd64-java]
{% endhighlight %}

The important bits in the above string is that it says the Java
VM is 64-bit. The JRuby version can and most likely will be different
as this documentation gets older and older.

Additionally, if the end of the string doesn't say `amd64` or `x86_64`, then
you might actually have a 32-bit OS installed, which means you should
follow the [normal Windows setup instructions](/docs/getting-started/setup/windows.html).
