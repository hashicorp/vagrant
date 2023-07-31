# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require "socket"

require "vagrant/util/is_port_open"

describe Vagrant::Util::IsPortOpen do
  subject { described_class }

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
    expect(subject.is_port_open?("127.0.0.1", open_port)).to be

    # Kill the thread
    thr[:die] = true
    thr.join
  end

  it "should report closed ports" do
    # This CAN fail, since port 52811 might actually be in use, but I'm
    # not sure what to do except choose some random port and hope for the
    # best, really.
    expect(subject.is_port_open?("127.0.0.1", closed_port)).not_to be
  end

  it "should handle connection refused" do
    expect(Socket).to receive(:tcp).with("0.0.0.0", closed_port, any_args).and_raise(Errno::ECONNREFUSED)
    expect(subject.is_port_open?("0.0.0.0", closed_port)).to be(false)
  end

  it "should raise an error if cannot assign requested address" do
    expect(Socket).to receive(:tcp).with("0.0.0.0", open_port, any_args).and_raise(Errno::EADDRNOTAVAIL)
    expect { subject.is_port_open?("0.0.0.0", open_port) }.to raise_error(Errno::EADDRNOTAVAIL)
  end

  it "should treat operation already in progress as unavailable" do
    expect(Socket).to receive(:tcp).with("0.0.0.0", closed_port, any_args).and_raise(Errno::EALREADY)
    expect(subject.is_port_open?("0.0.0.0", closed_port)).to be(false)
  end
end
