# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/action/is_windows")

describe VagrantPlugins::HyperV::Action::IsWindows do
  let(:app){ double("app") }
  let(:env){ {ui: ui, machine: machine} }
  let(:ui){ Vagrant::UI::Silent.new }
  let(:provider){ double("provider", driver: driver) }
  let(:driver){ double("driver") }
  let(:machine){ double("machine", provider: provider, config: config) }
  let(:config){ double("config", vm: vm) }
  let(:vm){ double("vm", guest: :windows) }
  let(:subject){ described_class.new(app, env) }

  before do
    allow(app).to receive(:call)
    allow(env).to receive(:[]=)
  end

  it "should call the app on success" do
    expect(app).to receive(:call)
    subject.call(env)
  end

  it "should update the env with the result" do
    expect(env).to receive(:[]=).with(:result, true)
    subject.call(env)
  end

  it "should set the result to false when not windows" do
    expect(vm).to receive(:guest).and_return(:linux)
    expect(env).to receive(:[]=).with(:result, false)
    subject.call(env)
  end

end
