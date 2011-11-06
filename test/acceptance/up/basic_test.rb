require File.expand_path("../../base", __FILE__)

class BasicUpTest < AcceptanceTest
  should "bring up a running virtual machine" do
    assert_execute("vagrant", "box", "add", "base", config.boxes["default"])
    assert_execute("vagrant", "init")
    assert_execute("vagrant", "up")
    result = assert_execute("vagrant", "status")

    assert(output(result.stdout).status("default", "running"),
           "Virtual machine should be running")
  end

=begin

TODO:

  should "fail if no `Vagrantfile` is found"
  should "be able to run if `Vagrantfile` is in parent directory"
  should "bring up a running virtual machine and be able to SSH into it"
  should "bring up a running virtual machine and have a `/vagrant' shared folder by default"
  should "destroy a running virtual machine"
  should "save then restore a virtual machine using `vagrant up`"
  should "halt then start a virtual machine using `vagrant up`"

This shows how we can test that SSH is working. We'll use
this code later, but for now have no test that exercises it.

    outputted = false
    result = assert_execute("vagrant", "ssh") do |io_type, data|
      if io_type == :stdin and !outputted
        data.puts("echo hello")
        data.puts("exit")
        outputted = true
      end
    end

    assert_equal("hello", result.stdout.chomp,
                 "Vagrant should bring up a virtual machine and be able to SSH in."
=end
end
