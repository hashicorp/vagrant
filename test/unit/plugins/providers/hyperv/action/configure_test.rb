# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/action/configure")

describe VagrantPlugins::HyperV::Action::Configure do
  let(:app){ double("app") }
  let(:env){ {ui: ui, machine: machine} }
  let(:ui){ Vagrant::UI::Silent.new }
  let(:provider){ double("provider", driver: driver) }
  let(:driver){ double("driver") }
  let(:machine){ double("machine", provider: provider, config: config, provider_config: provider_config, data_dir: data_dir, id: "machineID") }
  let(:data_dir){ double("data_dir") }
  let(:config){ double("config", vm: vm) }
  let(:vm){ double("vm", networks: networks) }
  let(:networks){ [] }
  let(:switches){ [
    {"Name" => "Switch1", "Id" => "ID1"},
    {"Name" => "Switch2", "Id" => "ID2"}
  ]}
  let(:sentinel){ double("sentinel") }
  let(:provider_config){
    double("provider_config",
      memory: "1024",
      maxmemory: "1024",
      cpus: 1,
      auto_start_action: "Nothing",
      auto_stop_action: "Save",
      enable_checkpoints: false,
      enable_automatic_checkpoints: true,
      enable_virtualization_extensions: false,
      vm_integration_services: vm_integration_services,
      enable_enhanced_session_mode: enable_enhanced_session_mode
    )
  }
  let(:vm_integration_services){ {} }
  let(:enable_enhanced_session_mode){ false }

  let(:subject){ described_class.new(app, env) }

  before do
    allow(driver).to receive(:execute)
    allow(app).to receive(:call)
    expect(driver).to receive(:execute).with(:get_switches).and_return(switches)
    allow(ui).to receive(:ask).and_return("1")
    allow(data_dir).to receive(:join).and_return(sentinel)
    allow(sentinel).to receive(:file?).and_return(false)
    allow(sentinel).to receive(:open)
    allow(driver).to receive(:set_enhanced_session_transport_type).with("VMBus")
  end

  it "should call the app on success" do
    expect(app).to receive(:call)
    subject.call(env)
  end

  context "with missing switch sentinel file" do
    it "should prompt for switch to use" do
      expect(ui).to receive(:ask)
      subject.call(env)
    end

    it "should write sentinel file" do
      expect(sentinel).to receive(:open)
      subject.call(env)
    end
  end

  context "with existing switch sentinel file" do
    before{ allow(sentinel).to receive(:file?).twice.and_return(true) }

    it "should not prompt for switch to use" do
      expect(ui).not_to receive(:ask)
      subject.call(env)
    end

    it "should not write sentinel file" do
      expect(sentinel).not_to receive(:open)
      subject.call(env)
    end
  end

  context "with bridge defined in networks" do
    context "with valid bridge switch name" do
      let(:networks){ [[:public_network, {bridge: "Switch1"}]] }

      it "should not prompt for switch" do
        expect(ui).not_to receive(:ask)
        subject.call(env)
      end
    end

    context "with valid bridge switch ID" do
      let(:networks){ [[:public_network, {bridge: "ID1"}]] }

      it "should not prompt for switch" do
        expect(ui).not_to receive(:ask)
        subject.call(env)
      end
    end

    context "with invalid bridge switch name" do
      let(:networks){ [[:public_network, {bridge: "UNKNOWN"}]] }

      it "should prompt for switch" do
        expect(ui).to receive(:ask)
        subject.call(env)
      end
    end
  end

  context "with integration services enabled" do
    let(:vm_integration_services){ {service: true} }

    it "should call the driver to set the services" do
      expect(driver).to receive(:set_vm_integration_services)
      subject.call(env)
    end
  end

  context "without enhanced session transport type" do
    it "should call the driver to set enhanced session transport type back to default" do
      expect(driver).to receive(:set_enhanced_session_transport_type).with("VMBus")
      subject.call(env)
    end
  end

  context "with enhanced session transport type" do
    let(:enable_enhanced_session_mode) { true }

    it "should call the driver to set enhanced session transport type" do
      expect(driver).to receive(:set_enhanced_session_transport_type).with("HvSocket")
      subject.call(env)
    end
  end

  context "without available switches" do
    let(:switches){ [] }

    it "should raise an error" do
      expect{ subject.call(env) }.to raise_error(VagrantPlugins::HyperV::Errors::NoSwitches)
    end
  end
end
