# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestDarwin::Cap::DarwinVersion" do
  let(:caps) do
    VagrantPlugins::GuestDarwin::Plugin
      .components
      .guest_capabilities[:darwin]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".darwin_version" do
    let(:cap) { caps.get(:darwin_version) }

    {
      "kern.osrelease: 19.6.0" => "19.6.0",
      "kern.osrelease: 20.1.10" => "20.1.10",
    }.each do |str, expected|
      it "returns #{expected} for #{str}" do
        comm.stub_command("sysctl kern.osrelease", stdout: str)
        expect(cap.darwin_version(machine)).to eq(expected)
      end
    end
  end

  describe ".darwin_major_version" do
    let(:cap) { caps.get(:darwin_major_version) }

    {
      "kern.osrelease: 19.6.0" => 19,
      "kern.osrelease: 20.1.10" => 20,
      "" => nil
    }.each do |str, expected|
      it "returns #{expected} for #{str}" do
        comm.stub_command("sysctl kern.osrelease", stdout: str)
        expect(cap.darwin_major_version(machine)).to eq(expected)
      end
    end
  end
end
