# This Vagrantfile can be used to develop Vagrant. Note that VirtualBox
# doesn't run in VirtualBox so you can't actually _run_ Vagrant within
# the VM created by this Vagrantfile, but you can use it to develop the
# Ruby, run unit tests, etc.

Vagrant.configure("2") do |config|
  config.ssh.connection_timeout = 30

  config.vm.provider "virtualbox" do |v|
    v.name = "my_vm",
    v.gui = false
  end

  ["a", "b"].each do |m|
    config.vm.define m do |c|
      c.vm.box = "hashicorp/bionic64"
      c.vm.network "forwarded_port", guest: 80, host: 8080

      c.vm.network "private_network", ip: "192.168.50.4", thing: "what"
      c.vm.network "public_network"
      c.vm.synced_folder "../tm", "/tm", type: "rsync", rsync__exclude: ".git/"
    end
  end

  config.vm.define "one" do |c|
    c.vm.box = "bento/ubuntu"
    c.vm.provision "shell", inline: "echo hello world"
    c.vm.provision "shell" do |s|
      s.inline = "echo goodbye"
    end
    c.vm.provision "file", source: "/Users/sophia/project/vagrant-ruby/.gitignore", destination: "/.gitignore" 
    c.vm.network "forwarded_port", guest: 80, host: 8080
    c.vm.synced_folder ".", "vagrant", disabled: true
  end

  config.vm.provision "shell", inline: "echo hello world"
  config.vm.provision "idontexistinruby", key: "val", foo: "bar", communicator_required: false
end

