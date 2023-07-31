# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/provisioners/container/client")

describe VagrantPlugins::ContainerProvisioner::Client do

  let(:machine) { double("machine", communicate: communicator, ui: ui) }
  let(:ui) { Vagrant::UI::Silent.new }
  let(:communicator) { double("communicator") }
  let(:container_command) { "CONTAINER_COMMAND" }
  subject { described_class.new(machine, container_command) }

  describe "#container_name" do
    it "converts a container name to a run appropriate form" do
      config = { :name => "test/test:1.1.1", :original_name => "test/test:1.1.1" }
      expect(subject.container_name(config)).to eq("test-test-1.1.1")
    end
  end

  describe "#build_images" do
    before { allow(communicator).to receive(:sudo) }

    it "should use sudo to run command" do
      expect(communicator).to receive(:sudo).with(/#{Regexp.escape(container_command)}/)
      subject.build_images([["path", {}]])
    end

    it "should output information to use" do
      expect(ui).to receive(:info).and_call_original
      subject.build_images([["path", {}]])
    end

    it "should handle communicator output" do
      expect(communicator).to receive(:sudo).with(/#{Regexp.escape(container_command)}/).
        and_yield(:stdout, "some output")
      subject.build_images([["path", {}]])
    end
  end

  describe "#pull_images" do
    before do
      allow(communicator).to receive(:sudo)
    end

    it "should use sudo to run command" do
      expect(communicator).to receive(:sudo).with(/#{Regexp.escape(container_command)}/)
      subject.pull_images(:image)
    end

    it "should output information to use" do
      expect(ui).to receive(:info).and_call_original
      subject.pull_images(:image)
    end
  end
end
