require File.expand_path("../../../base", __FILE__)

require "socket"

require "vagrant/util/is_port_open"

describe Vagrant::Util::IsPortOpen do
  let(:klass) do
    Class.new do
      extend Vagrant::Util::IsPortOpen
    end
  end

  let(:open_port)   { 52811 }
  let(:closed_port) { 52811 }

  it "should report open ports" do
    # Start a thread which listens on a port
    thr = Thread.new do
      server = TCPServer.new(open_port)
      Thread.current[:running] = true

      # Wait until we're told to die
      Thread.current[:die]     = false
      while !Thread.current[:die]
        Thread.pass
      end

      # Die!
      server.close
    end

    # Wait until the server is running
    while !thr[:running]
      Thread.pass
    end

    # Verify that we report the port is open
    expect(klass.is_port_open?("localhost", open_port)).to be

    # Kill the thread
    thr[:die] = true
    thr.join
  end

  it "should report closed ports" do
    # This CAN fail, since port 52811 might actually be in use, but I'm
    # not sure what to do except choose some random port and hope for the
    # best, really.
    expect(klass.is_port_open?("localhost", closed_port)).not_to be
  end
end

