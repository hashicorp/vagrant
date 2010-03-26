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
    for the job on all platforms.
  </p>
  <p>
    All Windows testing has been performed from the vanilla Windows XP command prompt. Cygwin support
    is planned but Vista, and Windows 7 testing will have to be a community effort.   
  </p>
  <p>
    If you are interested in testing the latest updates please do the following (requires a github account):
    
{% highlight bash %}
$ git clone git@github.com:mitchellh/vagrant.git
$ cd vagrant
$ rake install
{% endhighlight %}
   </p>
</div>

## Assumptions

The following assumes you have installed Ruby 1.8.6 or greater (see [here](http://www.ruby-lang.org/en/downloads/), in the Ruby on Windows section) with RubyGems and issued the following from a command prompt:

{% highlight bash %}
C:\> gem install vagrant
C:\> gem install win32console
{% endhighlight %}

Also, as with other platforms, you will need to have downloaded, installed, and opened [Oracle's Virtualbox](http://www.virtualbox.org/) at least once to generate the necessary configuration files for it, and vagrant, to run properly.

## Post Installation

After you have completed the above there are a few more important Windows specific configuration items to handle. 

### Adding VBoxManage to Your Path

Vagrant, and the virtualbox gem on which it relies, require that the VBoxManage utility is present in your Windows path. When VirtualBox is installed on Windows it doesn't add the utility to the Windows path automatically so you'll need to do that yourself. By default the utility is installed into 'C:\Program Files\Sun\Virtual Box'. If you've installed VirtualBox to a different location you'll need to use that directory when adding it to the path. 

![Copying MAC Address](/images/windows/vbox_manage_default_location.jpg)

You can add additional folders to Windows XP path by taking the following steps. First click Start, right click My Computer and select Properties. Select the Advanced tab in the window that pops up and find the Environment Variables button

![Environment Variables Button](/images/windows/environment_variables_button.jpg)

In the next window locate the System Variables list and find the Path variable. Click edit.

![Edit Path](/images/windows/edit_path.jpg)

Select the Variable value field and make your way to the end of the dialog to append the path that contains your VirtualBox install and the VBoxManage executable. Make sure to separate each path you add with a semi-colon.

![Alter Path](/images/windows/alter_path.jpg)

You can verify that VBoxManage has been made available by opening a command prompt and testing with `VBoxManage`. You should see the help listing for the tool. You can now continue with the installation of a base box and creation of your first Vagrant virtual machine.

{% highlight bash %}
C:\ > vagrant box add base http://files.vagrantup.com/base.box
C:\ > cd MyProjectDir
C:\ MyProjectDir> vagrant init
C:\ MyProjectDir> vagrant up
{% endhighlight %}

After this completes you'll need to move onto the following section to connect to your VM.

### Putty

Since SSH is not easy to use/install on the command line under Windows we have included a [Putty](http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html) formatted private key generated from the keypair included with the Vagrant gem. This allows quick and easy SSH access to all Base Boxes that leverage those keys.

To configure Putty we need 3 things: a user to log on with, the port that Vagrant forwarded for ssh, and the location of the ppk file. By default the first two will be `vagrant` and 2222, but there are many reasons those may be different, especially the port (other vm's services etc). If you've come here after following the quick start you'll have seen the following:

![No Vagrant SSH On Windows](/images/windows/port_and_ppk_path.jpg)

It's important to take note of both the port and the .ppk file location. If you've used the Ruby 1.8.6 installer, the above path will be the same for you. Moving on, once you've got Putty installed, opening putty.exe will present you with the connection configuration window. First enter the SSH information and a name for the connection, then open the SSH configuration sub-tree.

![Vagrant SSH Info Putty](/images/windows/putty_first_screen.jpg)

Here in the `Auth` configuration section we'll take the path information provided to us above and locate the .ppk file via the browse dialog.

![PPK Selection](/images/windows/ppk_selection.jpg)

Once you've done that head to the top of the configuration tree and click the `Session` tree item and save the putty configuration so it will be available for use again later.

![Save Result](/images/windows/save_result.jpg)

Last but not least, click the Open button to be presented with a bash prompt inside your new and shiny Vagrant virtual development environtment!

 
