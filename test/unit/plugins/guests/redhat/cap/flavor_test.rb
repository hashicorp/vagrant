# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestRedHat::Cap::Flavor" do
  let(:caps) do
    VagrantPlugins::GuestRedHat::Plugin
      .components
      .guest_capabilities[:redhat]
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

    # /etc/os-release was added in EL7+
    context "without /etc/os-release file" do
      {
        "" => :rhel
      }.each do |str, expected|
        it "returns #{expected} for #{str}" do
          comm.stub_command("test -f /etc/os-release", exit_code: 1)
          expect(cap.flavor(machine)).to be(expected)
        end
      end
    end
    context "with /etc/os-release file" do
      {
        "7" => :rhel_7,
        "8" => :rhel_8,
        "9.0" => :rhel_9,
        "9.1" => :rhel_9,
        "" => :rhel,
        "banana" => :rhel,
      }.each do |str, expected|
        it "returns #{expected} for #{str}" do
          comm.stub_command("test -f /etc/os-release", exit_code: 0)
          comm.stub_command("source /etc/os-release && printf $VERSION_ID", stdout: str)
          expect(cap.flavor(machine)).to be(expected)
        end
      end
    end
  end
end
