require File.expand_path("../base", __FILE__)

class SSHTest < AcceptanceTest
  should "fail if no Vagrantfile is found" do
    result = execute("vagrant", "ssh")
    assert(!result.success?, "vagrant ssh should fail")
    assert(output(result.stdout).no_vagrantfile,
           "Vagrant should error since there is no Vagrantfile")
  end

  should "fail if the virtual machine is not created" do
    assert_execute("vagrant", "init")

    result = execute("vagrant", "ssh")
    assert(!result.success?, "vagrant ssh should fail")
    assert(output(result.stdout).error_vm_must_be_created,
           "Vagrant should error that the VM must be created.")
  end

  should "be able to SSH into a running virtual machine" do
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

    assert_equal("hello", result.stdout.chomp,
                 "Vagrant should bring up a virtual machine and be able to SSH in.")
  end
end
