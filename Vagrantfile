# This Vagrantfile can be used to develop Vagrant. Note that VirtualBox
# doesn't run in VirtualBox so you can't actually _run_ Vagrant within
# the VM created by this Vagrantfile, but you can use it to develop the
# Ruby, run unit tests, etc.

Vagrant.configure("2") do |config|
  config.vm.define "one" do |c|
    c.vm.box = "hashicorp/bionic64"
    c.vm.provision "shell", inline: "echo hello world"
    c.vm.provision "shell" do |s|
      s.inline = "echo goodbye"
    end
    c.vm.provision "file", source: "/Users/sophia/project/vagrant-ruby/.gitignore", destination: "/.gitignore" 
  end

  ["a", "b"].each do |m|
    config.vm.define m do |c|
      c.vm.box = "hashicorp/bionic64"
    end
  end

  config.vm.provision "shell", inline: "echo hello world"
  config.vm.provision "idontexistinruby", key: "val", foo: "bar", communicator_required: false
end

