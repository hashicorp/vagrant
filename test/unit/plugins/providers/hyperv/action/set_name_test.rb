# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/action/set_name")

describe VagrantPlugins::HyperV::Action::SetName do
  let(:app){ double("app") }
  let(:env){ {ui: ui, machine: machine, root_path: Pathname.new("path")} }
  let(:ui){ Vagrant::UI::Silent.new }
  let(:provider){ double("provider", driver: driver) }
  let(:driver){ double("driver") }
  let(:machine){ double("machine", provider: provider, provider_config: provider_config, data_dir: data_dir, name: "machname") }
  let(:data_dir){ double("data_dir") }
  let(:provider_config){ double("provider_config", vmname: vmname) }
  let(:vmname){ "VMNAME" }
  let(:sentinel){ double("sentinel") }

  let(:subject){ described_class.new(app, env) }

  before do
    allow(driver).to receive(:set_name)
    allow(app).to receive(:call)
    allow(data_dir).to receive(:join).and_return(sentinel)
    allow(sentinel).to receive(:file?).and_return(false)
    allow(sentinel).to receive(:open)
  end

  it "should call the app on success" do
    expect(app).to receive(:call)
    subject.call(env)
  end

  it "should call the driver to set the name" do
    expect(driver).to receive(:set_name)
    subject.call(env)
  end

  it "should use the configured name when setting" do
    expect(driver).to receive(:set_name).with(vmname)
    subject.call(env)
  end

  it "should write sentinel after name is set" do
    expect(sentinel).to receive(:open)
    subject.call(env)
  end

  context "when no name is provided in the config" do
    let(:vmname){ nil }

    it "should generate a name based on path and machine" do
      expect(driver).to receive(:set_name).with(/^#{env[:root_path].to_s}_#{machine.name}_.+/)
      subject.call(env)
    end

    it "should not set name if sentinel exists" do
      expect(sentinel).to receive(:file?).and_return(true)
      subject.call(env)
    end
  end
end
