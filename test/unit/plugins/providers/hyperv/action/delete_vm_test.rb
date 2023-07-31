# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/action/delete_vm")

describe VagrantPlugins::HyperV::Action::DeleteVM do
  let(:app){ double("app") }
  let(:env){ {ui: ui, machine: machine} }
  let(:ui){ Vagrant::UI::Silent.new }
  let(:provider){ double("provider", driver: driver) }
  let(:driver){ double("driver") }
  let(:machine){ double("machine", provider: provider, data_dir: "/dev/null") }
  let(:subject){ described_class.new(app, env) }

  before do
    allow(app).to receive(:call)
    allow(driver).to receive(:delete_vm)
    allow(FileUtils).to receive(:rm_rf)
    allow(FileUtils).to receive(:mkdir_p)
  end

  it "should call the app on success" do
    expect(app).to receive(:call)
    subject.call(env)
  end

  it "should call the driver to delete the vm" do
    expect(driver).to receive(:delete_vm)
    subject.call(env)
  end

  it "should delete the data directory" do
    expect(FileUtils).to receive(:rm_rf).with(machine.data_dir)
    subject.call(env)
  end

  it "should recreate the data directory" do
    expect(FileUtils).to receive(:mkdir_p).with(machine.data_dir)
    subject.call(env)
  end
end
