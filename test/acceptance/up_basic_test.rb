require File.expand_path("../base", __FILE__)

describe "vagrant up", "basics" do
  include_context "acceptance"

  it "fails if not Vagrantfile is found" do
    result = execute("vagrant", "up")
    result.should_not be_success
    result.stdout.should match_output(:no_vagrantfile)
  end

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
