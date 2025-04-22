# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/communicators/none/communicator")

describe VagrantPlugins::CommunicatorNone::Communicator do
  include_context "unit"

  let(:machine) { double(:machine) }

  subject { described_class.new(machine) }

  context "#ready?" do
    it "should be true" do
      expect(subject.ready?).to be
    end
  end

  context "#execute" do
    it "should be successful regardless of command" do
      expect(subject.execute("/bin/false")).to eq(0)
    end
  end

  context "#sudo" do
    it "should be successful regardless of command" do
      expect(subject.execute("/bin/false")).to eq(0)
    end
  end

  context "test" do
    it "should be true" do
      expect(subject.test("/bin/false")).to be
    end
  end
end
