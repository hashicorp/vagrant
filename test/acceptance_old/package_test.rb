require File.expand_path("../base", __FILE__)
require "acceptance/support/shared/command_examples"

describe "vagrant package" do
  include_context "acceptance"

  # This creates an initial environment that is ready for a "vagrant up"
  def initialize_valid_environment
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")
  end

  it "can package a running virtual machine" do
    initialize_valid_environment

    assert_execute("vagrant", "up")
    assert_execute("vagrant", "package")
    environment.workdir.join("package.box").should be_file
  end

  it "can package a `base` VM directly from VirtualBox" do
    initialize_valid_environment

    # Use a custom Vagrantfile that sets the VM name to `foo`
    environment.workdir.join("Vagrantfile").open("w+") do |f|
      f.write(<<-vf)
Vagrant::Config.run do |config|
  config.vm.box = "base"
  config.vm.customize ["modifyvm", :id, "--name", "foo"]
end
vf
    end

    # Bring up the VM
    assert_execute("vagrant", "up")

    # Remove the Vagrantfile so it doesn't use that
    environment.workdir.join("Vagrantfile").unlink

    # Now package the base VM
    assert_execute("vagrant", "package", "--base", "foo")
    environment.workdir.join("package.box").should be_file
  end
end
