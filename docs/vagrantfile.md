---
layout: documentation
title: Documentation - Vagrantfile
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
1. Vagrantfile from the box directory is loaded if a box is specified.
1. Vagrantfile from the home directory (defaults to `~/.vagrant/`) is loaded if it exists.
1. Vagrantfile from the project directory is loaded. This is typically the
  file that users will be touching.

Therefore, the Vagrantfile in the project directory overwrites any conflicting
configuration from the home directory which overwrites any conflicting configuration
from a box which overwrites any conflicting configuration from
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
setup to use a specific user account for connecting. However, these settings are listed
here for documentation purposes:

`config.ssh.host` sets the SSH host. By default this is "localhost" but sometimes its useful
to change these to things such as "127.0.0.1."

`config.ssh.max_tries` specifies how many tries Vagrant attempts to connect to the
virtualized environment upon boot.

`config.ssh.private_key_path` is the path to the private key used to authenticate into
SSH. Typically you won't need to touch this unless the box you're using is setup
to use a custom SSH keypair.

`config.ssh.timeout` specifies the timeout when trying to connect to the virtual
environment.

`config.ssh.forward_agent` is a boolean which when true will enable agent forwarding for `vagrant ssh`.

`config.ssh.forward_x11` is a boolean which when true will enable X11 forwarding for `vagrant ssh`.

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

`config.vm.box_url`, if specified, will be used to download the box given in `config.vm.box`
if it doesn't exist. This URL can be anything which `vagrant box add` accepts as a
URL.

`config.vm.box_ovf` tells Vagrant and consequently the [virtualbox](http://github.com/mitchellh/virtualbox) gem
which file in the `~/.vagrant/boxes/{configured box}/` directory should be used when importing the configured box
for duplication. (see `config.vm.box`). This setting is only really important for those creating
boxes for distribution as this configuration should be included in the packaged Vagrantfile.

`config.vm.base_mac` configures the mac address that the vm will use when built. Because Vagrant duplicates virtual machines
and updating operating system configuration to accommodate changing mac addresses is non standard across operating systems it must
force a predetermined mac address at vm creation. This setting is also only useful for those creating boxes
for distribution.

`config.vm.customize` is a method which takes a block or lambda and allows you to customize the virtual machine
which Vagrant creates. The block is passed a [VirtualBox::VM](http://mitchellh.github.com/virtualbox/VirtualBox/VM.html)
object as its only parameter, and is automatically saved afterwards. Example:

{% highlight ruby %}
config.vm.customize do |vm|
  vm.memory_size = 512
  vm.name = "My Project VM"
end
{% endhighlight %}

`config.vm.define` is a method which allows you to define a new VM for a multi-VM environment. Since
this is a huge topic in itself, please read its dedicated documentation page for more details.

`config.vm.disk_image_format` alerts Vagrant to the prefered virtual disk image file format for use when creating new virtual machines. VirtualBox
supports many disk formats such as .vdi (VirtualBox's own format), .vmdk (VMWare's disk image format), and .vhd (Microsoft's format).

<a name="config-vm-forwardport"> </a>
`config.vm.forward_port` is a function that will add a set of ports to forward from the host machine to the virtual machine
created with vagrant. The default Vagrantfile that is packaged with Vagrant itself forwards port 2222 on the host machine to
port 22 on the guest for ssh. Example usage of this is shown below:

{% highlight ruby %}
config.vm.forward_port("web", 80, 8080)
config.vm.forward_port("ftp", 21, 4567)
config.vm.forward_port("ssh", 22, 2222, :auto => true)
{% endhighlight %}

The first parameter of the `forward_port` method is simply a key used internally to reference the
forwarded port. It doesn't affect the actual ports forwarded at all. The above example could've
changed `web` to `fluffy bananas` and it still would've worked fine.

The final parameter is a hash of options which can be used to configure details of the forwarded
ports. `:adapter` allows you to specify which network adapter to forward the ports on. And if `:auto`
is set to true, then Vagrant will attempt to find a new port if it detects that the specified
port would collide with another VM.

`config.vm.network` is a method which allows a static IP to be assigned to a VM via
host only networking. This is a large enough topic that it has its own page. Please
read the page on host only networking for more information and details.

`config.vm.provisioner` tells Vagrant which provisioner to use to provision the system. By
default, this is set to `nil` which disables provisioning. It can also be set to a symbol
to use a built-in provisioner, or a class to use a custom provisioner. Example:

{% highlight ruby %}
# Use a built-in provisioner
config.vm.provisioner = :chef_solo

# Use a custom provisioner
config.vm.provisioner = MyCustomProvisioner
{% endhighlight %}

`config.vm.share_folder` is a function that will share a folder on the host machine with the
guest machine, allowing the guest machine to read and write to a folder on the host machine.
This function takes three mandatory parameters, in the same way as `config.vm.forward_port`, with the
first parameter being a key used internally to reference the folder, the second parameter being
the path on the guest machine, and the third parameter being the path to the folder to share
on the host machine. If the third parameter is a _relative path_, then it is relative to where the root Vagrantfile is.

The method also takes a fourth, optional, parameter which is a hash of options. This hash
can be used to enable things such as [NFS shared folders](/docs/nfs.html).

{% highlight ruby %}
config.vm.share_folder("my-folder", "/folder", "/path/to/real/folder")
config.vm.share_folder("another-folder", "/other", "../other")
{% endhighlight %}

## config.package

These setting determine the defaults for the file name, `config.package.name`, and file extension, `config.package.extension`, used
when [packaging](/docs/getting-started/packaging.html) a vm for distribution.

## config.nfs

These settings configure [NFS shared folders](/docs/nfs.html), if they are used.

`config.nfs.map_uid` is the UID which any remote file accesses map to on the
host machine. By default this is set to `:auto`, which tells Vagrant to match
the UID of any NFS shared folders on the host machine.

`config.nfs.map_gid` is the same `config.nfs.map_uid` but for the GID of the
shared folder.

## config.chef

Vagrant can use [chef solo](/docs/provisioners/chef_solo.html) or [chef server](/docs/provisioners/chef_server.html)
to provision virtual environments. These are built-in provisioners which include their own configuration.

### Chef Solo Configuration

The settings below only have an effect if chef solo is used as the provisioner. Chef solo
provisioning can be enabled by setting `provisioner` to `:chef_solo`.

`config.chef.cookbooks_path` represents the cookbooks path on your host machine located relative to your project directory. Vagrant will expand whatever path you
place in this configuration option and use those cookbooks during provisioning. This value can also be an array of paths, which will cause
chef to look through all specified directories for the necessary cookbooks.

### Chef Server Configuration

The settings below only have an effect if chef server is used as the provisioner. Chef
server provisioning can be enabled by setting `provisioner` to `:chef_server`.

`config.chef.chef_server_url` represents the URL (and possibly port) to the chef server. An example is shown below:

{% highlight ruby %}
config.chef.chef_server_url = "http://mychefserver.com:4000"
{% endhighlight %}

`config.chef.validation_key_path` denotes the path to the validation key used to register a new node with
the chef server. This path is expanded relative to the project directory.

`config.chef.validation_client_name` is used to specify the name of the validation client. By default this is
set to `chef-validator` which is the default for chef server installations. Most of the time this won'
be changed.

`config.chef.client_key_path` is used to specify the path to store the client key once the
registration is complete. This defaults to `/etc/chef/client.pem`. This setting typically
doesn't need to be changed.

### Shared Chef Configuration

The configuration keys below are shared among chef solo and chef server, and affect
both.

`config.chef.json` is the place for any extra json that might be required for the chef solo command to properly provision your virtual machine. By default it includes

{% highlight ruby %}
config.chef.json = {
  :instance_role => "vagrant",
  :recipes => ["vagrant_main"]
}
{% endhighlight %}

This configuration value can be used to set attributes for the cookbooks used in provisioning.
For example, to set the MySQL root password used in the default [opscode mysql cookbook](http://github.com/opscode/cookbooks/tree/master/mysql/), it can be
configured in the Vagrantfile like so:

{% highlight ruby %}
config.chef.json.merge!({
  :mysql => {
    :server_root_password => "my_root_password"
  }
})
{% endhighlight %}

`config.chef.provisioning_path` is the folder on the virtual machine where Vagrant will copy a small ruby script to include the cookbooks and a json chef configuration file. A chef solo command will be issued from within this directory to put chef to work. This setting usually doesn't have to be changed.

{% highlight bash %}
$ sudo chef-solo -c solo.rb -j dna.json
{% endhighlight %}

`config.chef.run_list` is an array of recipes and/or roles to run on the node. This can be used to run
different recipes on the node. There are also helper methods `add_recipe` and `add_role` which can
be used as well.

{% highlight ruby %}
# Accessing the run list directly
config.chef.run_list = ["recipe[foo]", "recipe[bar]"]

# Using the helpers
config.chef.add_recipe("foo")
config.chef.add_role("bar")
{% endhighlight %}

## config.puppet

Vagrant can use [stand-alone Puppet](http://www.puppetlabs.com/puppet) to provision virtual environments. This is a built-in 
provisioner which includes its own configuration.

The settings below only have an effect if Puppet is used as the provisioner. Puppet
provisioning can be enabled by setting `provisioner` to `:puppet`.

`config.puppet.manifest_path` represents the manifests path on your host machine located relative to your project directory. Vagrant will expand whatever path you place in this configuration option and use those manifests during provisioning.

`config.puppet.pp_path` represents the path for your manifests on the virtual machine, it defaults to `/tmp/vagrant-puppet`.

## config.puppet_server

Also available is Puppet Server support which enables Puppet in client-server mode. 

The settings below only have an effect if Puppet is used as the provisioner. Puppet
provisioning can be enabled by setting `provisioner` to `:puppet_server`.

`config.puppet_server.puppet_server` specifies the name of the Puppet Server you wish to connect to, it defaults to `puppet`.

`config.puppet_server.puppet_node` specifies the node name of the VM you are configuring. Puppet uses this to identify what 
configuration to apply to the VM. If not specified it defaults to the name of the box being provisioned.
