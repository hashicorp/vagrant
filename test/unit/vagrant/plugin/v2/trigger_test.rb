require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V2::Trigger do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    isolated_environment.tap do |env|
      env.vagrantfile("")
    end
  end
  let(:iso_vagrant_env) { iso_env.create_vagrant_env }
  let(:machine) { iso_vagrant_env.machine(iso_vagrant_env.machine_names[0], :dummy) }
  let(:config)  { double("config") } # actually flush this out into a trigger config
  let(:env) { {
    machine: machine,
    ui: Vagrant::UI::Silent.new,
  } }


  let(:subject) { described_class.new(env, config, machine) }

  context "firing before triggers" do
  end

  context "firing after triggers" do
  end

  context "filtering triggers" do
  end

  context "firing triggers" do
  end

  context "executing info" do
    let(:message) { "Printing some info" }

    it "prints messages at INFO" do
      output = ""
      allow(machine.ui).to receive(:info) do |data|
        output << data
      end

      subject.send(:info, message)
      expect(output).to include(message)
    end
  end

  context "executing warn" do
    let(:message) { "Printing some warnings" }

    it "prints messages at WARN" do
      output = ""
      allow(machine.ui).to receive(:warn) do |data|
        output << data
      end

      subject.send(:warn, message)
      expect(output).to include(message)
    end
  end

  context "executing run" do
  end

  context "executing run_remote" do
  end
end
