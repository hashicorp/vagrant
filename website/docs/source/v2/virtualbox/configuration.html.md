---
page_title: "Configuration - VirtualBox Provider"
sidebar_current: "virtualbox-configuration"
---

# Configuration

The VirtualBox provider exposes some additional configuration options
that allow you to more finely control your VirtualBox-powered Vagrant
environments.

## GUI vs. Headless

By default, VirtualBox machines are started in headless mode, meaning
there is no UI for the machines visible on the host machine. Sometimes,
you want to have a UI. Common use cases include wanting to see a browser
that may be running in the machine, or debugging a strange boot issue.
You can easily tell the VirtualBox provider to boot with a GUI:

```
config.vm.provider "virtualbox" do |v|
  v.gui = true
end
```

## Virtual Machine Name

You can customize the name that appears in the VirtualBox GUI by
setting the `name` property. By default, Vagrant sets it to the containing
folder of the Vagrantfile plus a timestamp of when the machine was created.
By setting another name, your VM can be more easily identified.

```ruby
config.vm.provider "virtualbox" do |v|
  v.name = "my_vm"
end
```

## VBoxManage Customizations

[VBoxManage](http://www.virtualbox.org/manual/ch08.html) is a utility that can
be used to make modifications to VirtualBox virtual machines from the command
line.

Vagrant exposes a way to call any command against VBoxManage just prior
to booting the machine:

```ruby
config.vm.provider "virtualbox" do |v|
  v.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
end
```

In the example above, the VM is modified to have a host CPU execution
cap of 50%, meaning that no matter how much CPU is used in the VM, no
more than 50% would be used on your own host machine. Some details:

* The `:id` special parameter is replaced with the ID of the virtual
  machine being created, so when a VBoxManage command requires an ID, you
  can pass this special parameter.

* Multiple `customize` directives can be used. They will be executed in the
  order given.

There are some convenience shortcuts for memory and CPU settings:

```ruby
config.vm.provider "virtualbox" do |v|
  v.memory = 1024
  v.cpus = 2
end
```
