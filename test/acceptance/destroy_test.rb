require File.expand_path("../base", __FILE__)
require "acceptance/support/shared/command_examples"

describe "vagrant destroy" do
  include_context "acceptance"
  it_behaves_like "a command that requires a Vagrantfile", ["vagrant", "destroy"]

  it "succeeds and ignores if the VM is not created" do
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")

    result = assert_execute("vagrant", "destroy")
    result.stdout.should match_output(:vm_not_created_warning)
  end

  it "is able to destroy a running virtual machine" do
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")
    assert_execute("vagrant", "up")

    # Destroy the VM and assert that it worked properly (seemingly)
    result = assert_execute("vagrant", "destroy")
    result.stdout.should match_output(:vm_destroyed)

    # Assert that the VM no longer is created
    result = assert_execute("vagrant", "status")
    result.stdout.should match_output(:status, "default", "not created")
  end

  # TODO:
  # it is able to destroy a halted virtual machine
  # it is able to destroy a suspended virtual machine
end
