# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/action/read_guest_ip")

describe VagrantPlugins::HyperV::Action::ReadGuestIP do
  let(:app){ double("app") }
  let(:env){ {ui: ui, machine: machine} }
  let(:ui){ Vagrant::UI::Silent.new }
  let(:provider){ double("provider", driver: driver) }
  let(:driver){ double("driver") }
  let(:machine){ double("machine", provider: provider) }
  let(:subject){ described_class.new(app, env) }

  before do
    allow(app).to receive(:call)
    allow(env).to receive(:[]=)
    allow(machine).to receive(:id)
  end

  it "should call the app on success" do
    expect(app).to receive(:call)
    subject.call(env)
  end

  context "with machine ID set" do
    before{ allow(machine).to receive(:id).and_return("VMID") }

    it "should request guest IP from the driver" do
      expect(driver).to receive(:read_guest_ip).and_return("ip" => "ADDRESS")
      subject.call(env)
    end

    it "should set the host information into the env" do
      expect(env).to receive(:[]=).with(:machine_ssh_info, { host: "ADDRESS" })
      expect(driver).to receive(:read_guest_ip).and_return("ip" => "ADDRESS")
      subject.call(env)
    end
  end
end
