---
layout: guide
title: User Guide - Vagrantfile
---
# Vagrantfile

The Vagrantfile to Vagrant is just like what the Makefile is to the Make utility.
A single Vagrantfile exists at the root of every project which uses Vagrant, and
it is used to configure the virtual environment which Vagrant manages.

## Vagrantfile Load Order

Vagrant loads many Vagrantfiles whenever it is run, and the order they're loaded
determines the configuration values used. If there
are any configuration conflicts, the more recently loaded configuration
value overwrites the older value. Vagrant loads Vagrantfiles in the following order:

1. Vagrantfile from the gem directory is loaded. This contains all the defaults
  and should never be edited.
2. Vagrantfile from the box directory is loaded if a box is specified.
3. Vagrantfile from the project directory is loaded. This is typically the
  file that users will be touching.

Therefore, the Vagrantfile in the project directory overwrites any conflicting
configuration from a box which overwrites any conflicting configuration from
the default file.

## Vagrantfile Options

The Vagrantfile has many configurable options. To configure Vagrant, a configure
block must be created, which is passed in the configuration object. A brief example
is embedded below:

<a name="init-config"> </a>
{% highlight ruby %}
Vagrant::Config.run do |config|
  # Use the config object to do any configuration:
  config.vm.box = "my_box"
end
{% endhighlight %}

There are many available configuration options.

## config.vagrant

The vagrant configuration subset represents configuration settings for Vagrant itself and 
should _*not*_ be altered in your packaged box or project Vagrantfile.

## config.ssh

These settings will be used when logging into your Vagrant boxes. Generally, this will be configured
in the Vagrantfile packaged with any boxes you're using as the packaged virtual machine should have been
setup to use a specific user account for connecting. 

## config.vm

Vm settings are used when creating new virtual machines to alert Vagrant about how they 
should be configured for use. 

`config.vm.box` determines which of your boxes will be used when creating a new virtual machine for your project.
In many cases this will be the only configuration you'll ever have to do. The [example](#init-config) above represents a
Vagrantfile configuration where the box being used was installed with 

{% highlight bash %}
$ vagrant box add my_box http://some.url.for/some_remote_box.box
{% endhighlight %}

or 

{% highlight bash %}
$ vagrant box add my_box some_downloaded.box
{% endhighlight %}

`config.vm.box_ovf` tells Vagrant and consequently the [virtualbox](http://github.com/mitchellh/virtualbox) gem
which file in the ~/.vagrant/boxes/[configured box]/ directory should be used when importing the configured box 
for duplication. (see `config.vm.box`). This setting is only really important for those creating 
boxes for distribution as this configuration should be included in the packaged Vagrantfile.

`config.vm.base_mac` configures the mac address that the vm will use when built. Because Vagrant duplicates virtual machines
and updating operating system configuration to accomodate changing mac addresses is non standard across operating systems it must
force a predetermined mac address at vm creation.

`config.vm.project_directory` tells vagrant where to mount the current project directory as a shared folder
withing the new virtual machine's file system. 

{% highlight ruby %}
config.vm.project_directory = "/vagrant"
{% endhighlight %}

The above will use the vagrant folder under root as the mount point for the shared project directory.

`config.vm.forward_ports` is a function that will add a set of ports to forward from the host machine to the virtual machine
created with vagrant. The default Vagrantfile that is packaged with Vagrant itself forwards port 2222 on the host machine to 
port 22 on the guest for ssh. 

`config.vm.disk_image_format` alerts Vagrant to the prefered virtual disk image file format for use when creating new virtual machines. VirtualBox 
supports many disk formats such as .vdi (VirtualBox's own format), .vmdk (VMWare's disk image format), and .vhd (Microsoft's format).


## config.package

These setting determine the defaults for the file name, `config.package.name`, and file extension, `config.package.extension`, used
when [packaging](/docs/getting-started/packaging.html) a vm for distribution. 

## config.chef

Vagrant leverages Chef's ability to [provision](/docs/user-guide/provisioning.html) environments quickly and easily through this set of configuration options. 

`config.chef.enabled` is set to false in the default Vagrantfile and must be explicity turned on in a packaged or project specific Vagrantfile.

`config.chef.cooksbooks_path` represents the cookbooks path on your host machine located relative to your project directory. Vagrant will expand whatever path you
place in this configuration option and use those cookbooks during provisioning

`config.chef.provisioning_path` is the folder on the virtual machine where Vagrant will copy a small ruby script to include the cookbooks and a json chef configuration file.  
A chef solo command will be issued from within this directory to put chef to work.

{% highlight bash %}
$ sudo chef solo -c solo.rb -j dna.json
{% endhiglight %}

`config.chef.json` is the place for any extra json that might be required for the chef solo command to properly provision your virtual machine. By default it includes

{% highlight ruby %}
  config.chef.json = {
    :instance_role => "vagrant",
    :recipes => ["vagrant_main"]
  }
{% endhighlight %}

If you do not with to create a vagrant_main recipe in your cookbooks directory you can override the recipes hash key by placing `config.chef.json.merge({:recipes => 'you_want'})`
in either a packaged or project directory Vagrantfile.
