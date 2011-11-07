require File.expand_path("../base", __FILE__)

class SSHTest < AcceptanceTest
  should "bring up a running virtual machine and be able to SSH into it" do
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
