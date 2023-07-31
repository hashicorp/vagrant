# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/action/read_state")

describe VagrantPlugins::HyperV::Action::ReadState do
  let(:app){ double("app") }
  let(:env){ {ui: ui, machine: machine, machine_state_id: state_id} }
  let(:ui){ Vagrant::UI::Silent.new }
  let(:provider){ double("provider", driver: driver) }
  let(:driver){ double("driver") }
  let(:machine){ double("machine", provider: provider) }
  let(:state_id){ nil }

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

  it "should set machine state into the env as not created" do
    expect(env).to receive(:[]=).with(:machine_state_id, :not_created)
    subject.call(env)
  end

  context "with machine ID set" do
    before{ allow(machine).to receive(:id).and_return("VMID") }

    it "should request machine state from the driver" do
      expect(driver).to receive(:get_current_state).and_return("state" => "running")
      subject.call(env)
    end

    it "should set machine state into the env" do
      expect(driver).to receive(:get_current_state).and_return("state" => "running")
      expect(env).to receive(:[]=).with(:machine_state_id, :running)
      subject.call(env)
    end

    context "with machine state ID as not_created" do
      let(:state_id){ :not_created }

      it "should clear the machine ID" do
        expect(driver).to receive(:get_current_state).and_return("state" => "not_created")
        expect(machine).to receive(:id=).with(nil)
        subject.call(env)
      end
    end
  end
end
