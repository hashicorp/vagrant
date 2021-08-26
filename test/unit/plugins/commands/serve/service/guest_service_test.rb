require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/serve/command")

class DummyContext
  attr_reader :metadata
  def initialize(plugin_name)
    @metadata = {"plugin_name" => plugin_name}
  end
end

describe VagrantPlugins::CommandServe::Service::GuestService do
  include_context "unit"

  let(:broker){
    VagrantPlugins::CommandServe::Broker.new(bind: "bind_addr", ports: ["1234"])
  }

  let(:machine_arg){ 
    Hashicorp::Vagrant::Sdk::FuncSpec::Args.new(
      args: [
        Hashicorp::Vagrant::Sdk::FuncSpec::Value.new(
          name: "", 
          type: "hashicorp.vagrant.sdk.Args.Target", 
          value: Google::Protobuf::Any.pack(
            Hashicorp::Vagrant::Sdk::Args::Target.new(
              stream_id: 1,
              network: "here:101",
              target: "unix://here"
            )
          )
        )
      ]
    )
  }

  subject { described_class.new(broker: broker) }

  context "requesting parents" do
    it "generates a spec" do
      spec = subject.parents_spec
      expect(spec).not_to be_nil
    end

    it "raises an error for unknown plugins" do
      ctx = DummyContext.new("idontexisthahaha")
      expect { subject.parents("", ctx) }.to raise_error
    end

    it "requests parents from plugins" do
      ctx = DummyContext.new("ubuntu")
      parents = subject.parents("", ctx)
      expect(parents).not_to be_nil
      expect(parents.parents).to include("ubuntu")
    end
  end

end
