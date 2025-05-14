# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::CloudInitWait do

  let(:app) { lambda { |env| } }
  let(:config) { double("config", :vm => vm) }
  let(:comm) { double("comm") }
  let(:machine) { double("machine", :config => config, :communicate => comm, :name => "test", id: "m-id", data_dir: data_dir) }
  let(:data_dir) { double("data_dir") }
  let(:ui) { Vagrant::UI::Silent.new }
  let(:env) { { machine: machine, ui: ui} }
  let(:sentinel) { double("sentinel_path", unlink: nil) }

  let(:subject) { described_class.new(app, env) }

  describe "#call" do
    let(:sentinel_exists) { false }
    let(:sentinel_contents) { "" }

    before do
      allow(data_dir).to receive(:join).with("action_cloud_init").and_return(sentinel)
      allow(sentinel).to receive(:file?).and_return(sentinel_exists)
      allow(sentinel).to receive(:read).and_return(sentinel_contents)
      allow(sentinel).to receive(:write).with(machine.id)
      allow(comm).to receive(:test).with("command -v cloud-init").and_return(true)
      allow(comm).to receive(:sudo).with("cloud-init status --wait", error_check: false).and_return(0)
    end

    context "cloud init configuration exists" do
      let(:vm) { double("vm", cloud_init_configs: ["some config"]) }

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

      context "when sentinel file exists" do
        let(:sentinel_exists) { true }

        context "when sentinel contents is machine id" do
          let(:sentinel_contents) { machine.id.to_s }

          it "should not test for cloud-init" do
            expect(comm).not_to receive(:test).with(/cloud-init/)
            subject.call(env)
          end

          it "should not run cloud-init" do
            expect(comm).not_to receive(:sudo).with(/cloud-init/, anything)
            subject.call(env)
          end

          it "should not write sentinel file" do
            expect(sentinel).not_to receive(:write)
            subject.call(env)
          end
        end

        context "when sentinel content is not machine id" do
          let(:sentinel_contents) { "unknown-id" }

          it "should test for cloud-init" do
            expect(comm).to receive(:test).with(/cloud-init/)
            subject.call(env)
          end

          it "should run cloud-init" do
            expect(comm).to receive(:sudo).with(/cloud-init/, anything)
            subject.call(env)
          end

          it "should write sentinel file" do
            expect(sentinel).to receive(:write).with(machine.id)
            subject.call(env)
          end
        end
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
