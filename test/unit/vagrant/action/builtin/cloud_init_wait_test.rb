# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::CloudInitWait do

  let(:app) { lambda { |env| } }
  let(:config) { double("config", :vm => vm) }
  let(:comm) { double("comm") }
  let(:machine) { double("machie", :config => config, :communicate => comm, :name => "test") }
  let(:ui) { Vagrant::UI::Silent.new }
  let(:env) { { machine: machine, ui: ui} }

  let(:subject) { described_class.new(app, env) }

  describe "#call" do

    context "cloud init configuration exists" do

      let(:vm) { double("vm", cloud_init_configs: ["some config"]) }

      before do
        allow(comm).to receive(:test).with("command -v cloud-init").and_return(true)
      end

      it "waits for cloud init to be executed" do
        expect(comm).to receive(:sudo).with("cloud-init status --wait", any_args).and_return(0)
        subject.call(env)
      end

      it "raises an error when cloud init not installed" do
        allow(comm).to receive(:test).with("command -v cloud-init").and_return(false)
        expect { subject.call(env) }.
          to raise_error(Vagrant::Errors::CloudInitNotFound)
      end

      it "raises an error when cloud init command fails" do
        expect(comm).to receive(:sudo).with("cloud-init status --wait", any_args).and_return(1)
        expect { subject.call(env) }.
          to raise_error(Vagrant::Errors::CloudInitCommandFailed)
      end
    end

    context "no cloud init configuration" do

      let(:vm) { double("vm", cloud_init_configs: []) }

      before do
        allow(comm).to receive(:test).with("command -v cloud-init").and_return(true)
      end

      it "does not wait for cloud init if there are no cloud init configs" do
        expect(comm).to_not receive(:sudo).with("cloud-init status --wait", any_args)
        subject.call(env)
      end
    end
  end
end
