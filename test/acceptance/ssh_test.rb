require File.expand_path("../base", __FILE__)
require "acceptance/support/shared/command_examples"

describe "vagrant ssh" do
  include_context "acceptance"
  it_behaves_like "a command that requires a Vagrantfile", ["vagrant", "ssh"]
  it_behaves_like "a command that requires a virtual machine", ["vagrant", "ssh"]

  it "is able to SSH into a running virtual machine" do
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")
    assert_execute("vagrant", "up")

    outputted = false
    result = assert_execute("vagrant", "ssh") do |io_type, data|
      if io_type == :stdin and !outputted
        data.puts("echo hello")
        data.puts("exit")
        outputted = true
      end
    end

    result.stdout.chomp.should eql("hello"), "Vagrant should bring up a VM to be able to SSH into."
  end

  it "is able to execute a single command via the command line" do
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")
    assert_execute("vagrant", "up")

    result = assert_execute("vagrant", "ssh", "-c", "echo foo")
    result.stdout.should == "foo\n"
  end

  # TODO:
  # SSH should fail if the VM is not running
end
