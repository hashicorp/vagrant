require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::CloudInitWait do
 
  let(:app) { lambda { |env| } }
  let(:config) { double("config", vm: vm) }
  let(:comm) { double("comm") }
  let(:machine) { double("machie", config: config, communicate: comm) }
  let(:env) { { machine: machine} }

  let(:subject) { described_class.new(app, env) }

  describe "#call" do
    context "cloud init configuration exists" do
      
      let(:vm) { double("vm", cloud_init_configs: ["some config"]) }
      
      it "waits for cloud init to be executed" do
        expect(comm).to receive(:sudo).with("cloud-init status --wait", any_args)
        subject.call(env)
      end
    end

    context "no cloud init configuration" do
      
      let(:vm) { double("vm", cloud_init_configs: []) }

      it "does not wait for cloud init if there are no cloud init configs" do
        expect(comm).to_not receive(:sudo).with("cloud-init status --wait", any_args)
        subject.call(env)
      end
    end
  end
end
