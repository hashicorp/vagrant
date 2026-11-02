# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative '../base'

describe VagrantPlugins::ProviderVirtualBox::Action::CleanMachineFolder do
  let(:app) { double("app") }
  let(:driver) { double("driver") }
  let(:machine) { double("machine", provider: double("provider", driver: driver), name: "") }
  let(:env) {
    { machine: machine }
  }
  let(:subject) { described_class.new(app, env) }

  before do
    allow(driver).to receive(:read_machine_folder)
  end

  context "machine folder is not accessible" do
    before do
      allow(subject).to receive(:clean_machine_folder).and_raise(Errno::EPERM)
    end

    it "raises an error" do
      expect { subject.call(env) }.to raise_error(Vagrant::Errors::MachineFolderNotAccessible)
    end
  end
end
