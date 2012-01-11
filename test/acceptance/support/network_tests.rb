require "vagrant/util/retryable"

module Acceptance
  module NetworkTests
    include Vagrant::Util::Retryable

    # Tests that the host can access the VM through the network.
    #
    # @param [String] url URL to request from the host.
    # @param [Integer] guest_port Port to run a web server on the guest.
    def assert_host_to_vm_network(url, guest_port)
      # Start up a web server in another thread by SSHing into the VM.
      thr = Thread.new do
        assert_execute("vagrant", "ssh", "-c", "python -m SimpleHTTPServer #{guest_port}")
      end

      # Verify that port forwarding works by making a simple HTTP request
      # to the port. We should get a 200 response. We retry this a few times
      # as we wait for the HTTP server to come online.
      retryable(:tries => 5, :sleep => 2) do
        result = Net::HTTP.get_response(URI.parse(url))
        result.code.should == "200"
      end
    ensure
      # The server needs to die. This is how.
      thr.kill if thr
    end
  end
end
