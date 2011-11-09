require File.expand_path("../base", __FILE__)

describe "vagrant ssh" do
  include_context "acceptance"

  it "fails if no Vagrantfile is found" do
    result = execute("vagrant", "ssh")
    result.should_not be_success
    result.stdout.should match_output(:no_vagrantfile)
  end

  it "fails if the virtual machine is not created" do
    assert_execute("vagrant", "init")

    result = execute("vagrant", "ssh")
    result.should_not be_success
    result.stdout.should match_output(:error_vm_must_be_created)
  end

  it "is able to SSH into a running virtual machine" do
    assert_execute("vagrant", "box", "add", "base", config.boxes["default"])
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
    assert_execute("vagrant", "box", "add", "base", config.boxes["default"])
    assert_execute("vagrant", "init")
    assert_execute("vagrant", "up")

    result = assert_execute("vagrant", "ssh", "-c", "echo foo")
    result.stdout.should == "foo\n"
  end
end
