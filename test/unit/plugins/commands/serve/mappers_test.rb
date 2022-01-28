require File.expand_path("../../../base", __dir__)

require Vagrant.source_root.join("plugins/commands/serve/command")

describe VagrantPlugins::CommandServe::Mappers do
  include_context "unit"

  subject { described_class.new }

  context "Hash" do
    it "unwraps wrapper types when they show up in the Hash" do
      input = Hashicorp::Vagrant::Sdk::Args::Hash.new(
        fields: {
          "error_check" => Google::Protobuf::Any.pack(
            Google::Protobuf::BoolValue.new(value: false)
          )
        }
      )
      output = subject.map(input, to: Hash)

      expect(output).to eq({error_check: false})
    end
  end

  context "Array" do
    it "unwraps wrapper types when they show up in the Array" do
      input = Hashicorp::Vagrant::Sdk::Args::Array.new(
        list: [
          Google::Protobuf::Any.pack(
            Google::Protobuf::BoolValue.new(value: false)
          ),
        ],
      )
      output = subject.map(input, to: Array)

      expect(output).to eq([false])
    end
  end
end
