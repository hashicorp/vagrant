# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require_relative "../../../../../../plugins/hosts/windows/cap/configured_ip_addresses"

describe VagrantPlugins::HostWindows::Cap::ConfiguredIPAddresses do

  let(:subject){ VagrantPlugins::HostWindows::Cap::ConfiguredIPAddresses }
  let(:result){ Vagrant::Util::Subprocess::Result }
  let(:addresses){ [] }
  let(:execute_result){ result.new(0, {ip_addresses: addresses}.to_json, "") }

  before{ allow(Vagrant::Util::PowerShell).to receive(:execute).
      and_return(execute_result) }

  it "should return an array" do
    expect(subject.configured_ip_addresses(nil)).to be_kind_of(Array)
  end

  context "with single address returned" do
    let(:addresses){ "ADDRESS" }

    it "should return an array" do
      expect(subject.configured_ip_addresses(nil)).to eq([addresses])
    end
  end

  context "with multiple addresses returned" do
    let(:addresses){ ["ADDRESS1", "ADDRESS2"] }

    it "should return an array" do
      expect(subject.configured_ip_addresses(nil)).to eq(addresses)
    end
  end

  context "with failed script execution" do
    let(:execute_result){ result.new(1, "", "") }

    it "should raise error" do
      expect{ subject.configured_ip_addresses(nil) }.to raise_error(
        Vagrant::Errors::PowerShellError)
    end
  end
end
