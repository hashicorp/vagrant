require File.expand_path("../base", __FILE__)
require "support/shared/command_examples"

describe "vagrant up", "basics" do
  include_context "acceptance"
  it_behaves_like "a command that requires a Vagrantfile", ["vagrant", "up"]

  it "brings up a running virtual machine" do
    assert_execute("vagrant", "box", "add", "base", config.boxes["default"])
    assert_execute("vagrant", "init")
    assert_execute("vagrant", "up")
    result = assert_execute("vagrant", "status")
    result.stdout.should match_output(:status, "default", "running")
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
