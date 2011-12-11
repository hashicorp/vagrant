require File.expand_path("../base", __FILE__)
require "acceptance/support/shared/command_examples"

describe "vagrant suspend" do
  include_context "acceptance"
  it_behaves_like "a command that requires a Vagrantfile", ["vagrant", "suspend"]

  it "succeeds and ignores if the VM is not created" do
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")

    result = assert_execute("vagrant", "suspend")
    result.stdout.should match_output(:vm_not_created_warning)
  end

  it "is able to suspend a running virtual machine" do
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")
    assert_execute("vagrant", "up")

    # Suspend the VM and assert that it worked properly (seemingly)
    result = assert_execute("vagrant", "suspend")
    result.stdout.should match_output(:vm_suspending)

    # Assert that the VM is no longer running
    result = assert_execute("vagrant", "status")
    result.stdout.should match_output(:status, "default", "saved")
  end

  # These tests are parameterized since both "vagrant resume" and
  # "vagrant up" should achieve the same result.
  ["resume", "up"].each do |command|
    it "is able to resume after the machine has been suspended using #{command}" do
      require_box("default")

      assert_execute("vagrant", "box", "add", "base", box_path("default"))
      assert_execute("vagrant", "init")
      assert_execute("vagrant", "up")
      assert_execute("vagrant", "suspend")

      # Assert that the VM is no longer running
      result = assert_execute("vagrant", "status")
      result.stdout.should match_output(:status, "default", "saved")

      assert_execute("vagrant", command)

      # Assert that the VM is once again running
      result = assert_execute("vagrant", "status")
      result.stdout.should match_output(:status, "default", "running")
    end
  end
end
