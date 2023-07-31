# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestAlma::Cap::Flavor" do
  let(:caps) do
    VagrantPlugins::GuestAlma::Plugin
      .components
      .guest_capabilities[:alma]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".flavor" do
    let(:cap) { caps.get(:flavor) }

    {
      "" => :alma,
      "8.2" => :alma_8,
      "9" => :alma_9,
      "invalid" => :alma
    }.each do |str, expected|
      it "returns #{expected} for #{str}" do
        comm.stub_command("source /etc/os-release && printf $VERSION_ID", stdout: str)
        expect(cap.flavor(machine)).to be(expected)
      end
    end
  end
end
