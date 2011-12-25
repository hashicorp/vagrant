require File.expand_path("../base", __FILE__)

require "net/http"
require "uri"

require "vagrant/util/retryable"

require "acceptance/support/shared/command_examples"

describe "vagrant port forwarding" do
  include Vagrant::Util::Retryable

  include_context "acceptance"

  it "forwards ports properly" do
    require_box("default")

    guest_port = 3000
    host_port  = 5000

    environment.workdir.join("Vagrantfile").open("w+") do |f|
      f.puts(<<VFILE)
Vagrant::Config.run do |config|
  config.vm.box = "base"
  config.vm.forward_port "foo", #{guest_port}, #{host_port}
end
VFILE
    end

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "up")

    # Start up a web server in another thread by SSHing into the VM.
    thr = nil
    begin
      thr = Thread.new do
        assert_execute("vagrant", "ssh", "-c", "python -m SimpleHTTPServer #{guest_port}")
      end

      retryable(:tries => 5, :sleep => 2) do
        # Verify that port forwarding works by making a simple HTTP request
        # to the port. We should get a 200 response.
        result = Net::HTTP.get_response(URI.parse("http://localhost:#{host_port}/"))
        result.code.should == "200"
      end
    ensure
      # The server needs to die. This is how.
      thr.kill if thr
    end
  end
end
