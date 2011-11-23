require File.expand_path("../base", __FILE__)
require "support/shared/command_examples"

describe "vagrant halt" do
  include_context "acceptance"
  it_behaves_like "a command that requires a Vagrantfile", ["vagrant", "halt"]

  it "succeeds and ignores if the VM is not created" do
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")

    result = assert_execute("vagrant", "halt")
    result.stdout.should match_output(:vm_not_created_warning)
  end

  it "is able to halt a running virtual machine" do
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")
    assert_execute("vagrant", "up")

    # Halt the VM and assert that it worked properly (seemingly)
    result = assert_execute("vagrant", "halt")
    result.stdout.should match_output(:vm_halt_graceful)

    # Assert that the VM no longer is created
    result = assert_execute("vagrant", "status")
    result.stdout.should match_output(:status, "default", "powered off")
  end

  it "is able to force halt a running virtual machine" do
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")
    assert_execute("vagrant", "up")

    # Halt the VM and assert that it worked properly (seemingly)
    result = assert_execute("vagrant", "halt", "--force")
    result.stdout.should match_output(:vm_halt_force)

    # Assert that the VM no longer is created
    result = assert_execute("vagrant", "status")
    result.stdout.should match_output(:status, "default", "powered off")
  end

  # TODO:
  # halt behavior on suspend machine
  # halt behavior if machine is already powered off
  # VM can come back up after a halt
end
