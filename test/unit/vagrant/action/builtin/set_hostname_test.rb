# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::SetHostname do
  let(:env) { { machine: machine, ui: ui } }
  let(:app) { lambda { |env| } }
  let(:machine) { double("machine") }
  let(:ui) { Vagrant::UI::Silent.new }

  subject { described_class.new(app, env) }

  before do
    allow(machine).to receive_message_chain(:config, :vm, :hostname).and_return("whatever")
    allow(machine).to receive_message_chain(:guest, :capability)
  end

  it "should change hostname if hosts modification enabled" do
    allow(machine).to receive_message_chain(:config, :vm, :allow_hosts_modification).and_return(true)
    expect(machine).to receive(:guest)
    subject.call(env)
  end

  it "should not change hostname if hosts modification disabled" do
    allow(machine).to receive_message_chain(:config, :vm, :allow_hosts_modification).and_return(false)
    expect(machine).not_to receive(:guest)
    subject.call(env)
  end
end
