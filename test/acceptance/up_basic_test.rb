require File.expand_path("../base", __FILE__)
require "acceptance/support/shared/command_examples"

describe "vagrant up", "basics" do
  include_context "acceptance"
  it_behaves_like "a command that requires a Vagrantfile", ["vagrant", "up"]

  # This creates an initial environment that is ready for a "vagrant up"
  def initialize_valid_environment
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")
  end

  it "brings up a running virtual machine" do
    initialize_valid_environment

    assert_execute("vagrant", "up")
    result = assert_execute("vagrant", "status")
    result.stdout.should match_output(:status, "default", "running")
  end

  it "is able to run if Vagrantfile is in a parent directory" do
    initialize_valid_environment

    # Create a subdirectory in the working directory and use
    # that as the CWD for `vagrant up` and verify it still works
    foodir = environment.workdir.join("foo")
    foodir.mkdir
    assert_execute("vagrant", "up", :chdir => foodir.to_s)
  end

  it "should have a '/vagrant' shared folder" do
    initialize_valid_environment

    # This is the file that will be created from the VM,
    # but should then exist on the host machine
    foofile = environment.workdir.join("foo")

    assert_execute("vagrant", "up")
    foofile.exist?.should_not be,
        "'foo' should not exist yet."

    assert_execute("vagrant", "ssh", "-c", "touch /vagrant/foo")
    foofile.exist?.should be, "'foo' should exist since it was touched in the shared folder"
  end

=begin

TODO:

  should "destroy a running virtual machine"
  should "save then restore a virtual machine using `vagrant up`"
  should "halt then start a virtual machine using `vagrant up`"

=end
end
