# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __dir__)

require Vagrant.source_root.join("plugins/commands/serve/command")

describe VagrantPlugins::CommandServe::Mappers do
  include_context "unit"

  subject { described_class.new }

  context "Hash" do
    it "unwraps wrapper types when they show up in the Hash" do
      input = Hashicorp::Vagrant::Sdk::Args::Hash.new(
        entries: [
          Hashicorp::Vagrant::Sdk::Args::HashEntry.new(
            key: Google::Protobuf::Any.pack(
              Hashicorp::Vagrant::Sdk::Args::Symbol.new(str: "error_check")
            ),
            value: Google::Protobuf::Any.pack(
              Google::Protobuf::BoolValue.new(value: false)
            )
          )
        ]
      )
      output = subject.map(input, to: Hash)

      expect(output[:error_check]).to eq(false)

      input = Hashicorp::Vagrant::Sdk::Args::Hash.new(
        entries: [
          Hashicorp::Vagrant::Sdk::Args::HashEntry.new(
            key: Google::Protobuf::Any.pack(
              Google::Protobuf::StringValue.new(value: "error_check")
            ),
            value: Google::Protobuf::Any.pack(
              Google::Protobuf::BoolValue.new(value: false)
            )
          )
        ]
      )
      output = subject.map(input, to: Hash)

      expect(output["error_check"]).to eq(false)
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

  context "MachineState" do
    it "yields an id that's a symbol, not a string" do
      input = Hashicorp::Vagrant::Sdk::Args::Target::Machine::State.new(
        id: "running",
      )
      output = subject.map(input, to: Vagrant::MachineState)

      expect(output.id).to eq(:running)
    end
  end
end
