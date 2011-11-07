require File.expand_path("../base", __FILE__)

class UpBasicTest < AcceptanceTest
  should "fail if not Vagrantfile is found" do
    result = execute("vagrant", "up")
    assert(!result.success?, "vagrant up should fail")
    assert(output(result.stdout).no_vagrantfile,
           "Vagrant should error since there is no Vagrantfile")
  end

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

  should "be able to run if `Vagrantfile` is in parent directory"
  should "bring up a running virtual machine and have a `/vagrant' shared folder by default"
  should "destroy a running virtual machine"
  should "save then restore a virtual machine using `vagrant up`"
  should "halt then start a virtual machine using `vagrant up`"

=end
end
