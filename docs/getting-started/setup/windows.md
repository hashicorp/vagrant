---
layout: getting_started
title: Windows
---
# Windows

<div class="info">
  <h3>Windows Support</h3>
  <p>
    Windows support is a recent addition to vagrant so if you do experience trouble
    or find this section hard to follow, please see the <a href='/support.html'>support page</a>
    and let us know so we can help you. Our goal is to make Vagrant the best tool
    for the job on as many platforms as possible.
  </p>
  <p>
    All Windows testing has been performed from the vanilla Windows XP command prompt. Cygwin support
    is planned but Vista and Windows 7 testing will have to be a community effort. If you are interested
    in testing the latest updates please checkout the <a href='http://github.com/mitchellh/vagrant'>github page</a>.
   </p>
</div>

## Install Ruby and Vagrant

The first step is to get Ruby and RubyGems running on Windows. We recommend [RubyInstaller](http://rubyinstaller.org/) for
a quick one-click solution, and this is the solution we support. There are, however, [other methods](http://www.ruby-lang.org/en/downloads/) to getting
Ruby running on windows.

Once Ruby and RubyGems are installed, install Vagrant with a single command:

{% highlight bash %}
C:\> gem install vagrant
{% endhighlight %}

Finally, as with other platforms, you will need to have downloaded and installed [Oracle's Virtualbox](http://www.virtualbox.org/)
for Vagrant to run properly. Vagrant will verify this when it is first run.

## Good to go!

With Vagrant installed, you can now follow the remainder of the [getting started guide](/docs/getting-started/index.html)
just like any other Vagrant user and everything should work the same across all
operating systems, including Windows.

The only difference is `vagrant ssh` and this is covered below:

#### SSH

Since SSH is not easy to use/install on the command line under Windows we have included
a [Putty](http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html) formatted private
key generated from the key pair included with the Vagrant gem. This allows quick and easy SSH
access to all base boxes that leverage that key pair.

To configure Putty we need 3 things: a user to log on with, the port that Vagrant forwarded for ssh,
and the location of the ppk file. By default the first two will be `vagrant` and `2222`, but there
are many reasons those may be different, especially the port (other vm's services etc). At this point
if you issue `vagrant ssh` from the directory where you created your initial vm you should see
something like the following:

![No Vagrant SSH On Windows](/images/windows/port_and_ppk_path.jpg)

It's important to take note of both the port and the .ppk file location. If you've used the Ruby installer,
the above path will be the same for you taking into account the version of the Vagrant gem you have installed.
Moving on, once you've got Putty installed, opening putty.exe will present you with the connection
configuration window. First enter the SSH information and a name for the connection, then open the SSH
configuration sub-tree.

![Vagrant SSH Info Putty](/images/windows/putty_first_screen.jpg)

Here in the `Auth` configuration section we'll take the path information provided to us above and locate
the .ppk file via the browse dialog.

![PPK Selection](/images/windows/ppk_selection.jpg)

Once you've done that head to the top of the configuration tree, click the `Session` tree item and save
the putty configuration so it will be available for use again later.

![Save Result](/images/windows/save_result.jpg)

Last but not least, click the Open button to be presented with a bash prompt inside your new and shiny
Vagrant virtual development environtment! If you've taken the steps above to save the configuration it
should be easy to use and adapt to other virtual environments created with Vagrant.


