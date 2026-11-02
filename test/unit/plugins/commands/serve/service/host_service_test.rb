# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/serve/command")
require Vagrant.source_root.join("plugins/commands/serve/broker").to_s

class DummyContext
  attr_reader :metadata
  def initialize(plugin_name)
    @metadata = {"plugin_name" => plugin_name}
  end
end

describe VagrantPlugins::CommandServe::Service::HostService do
  include_context "unit"

  let(:broker){
    VagrantPlugins::CommandServe::Broker.new(bind: "bind_addr", ports: ["1234"])
  }

  let(:machine){ double("machine") }

  let(:statebag_arg){
    Hashicorp::Vagrant::Sdk::FuncSpec::Args.new(
      args: [
        Hashicorp::Vagrant::Sdk::FuncSpec::Value.new(
          name: "",
          type: "hashicorp.vagrant.sdk.Args.StateBag",
          value: Google::Protobuf::Any.pack(
            Hashicorp::Vagrant::Sdk::Args::StateBag.new(stream_id: 1, network: "here:101", addr: "unix://here"
        )))
      ]
    )
  }

  let(:statebag) { double("statebag") }
  subject { described_class.new(broker: broker) }

  before(:each) do
    allow(Hashicorp::Vagrant::Sdk::StateBagService::Stub).
      to receive(:new).and_return(statebag)

    parent_test_host = Class.new(Vagrant.plugin("2", :host)) do
      def detect?(env)
        true
      end
    end

    test_host = Class.new(Vagrant.plugin("2", :host)) do
      def detect?(env)
        true
      end
    end

    register_plugin do |p|
      p.host(:parent_test) { parent_test_host }
      p.host(:test, :parent_test) { test_host }
    end
  end

  context "requesting parent" do
    it "generates a spec" do
      spec = subject.parent_spec
      expect(spec).not_to be_nil
    end

    it "raises an error for unknown plugins" do
      ctx = DummyContext.new("idontexisthahaha")
      expect { subject.parent("", ctx) }.to raise_error(GRPC::BadStatus)
    end

    it "requests parent from plugins" do
      ctx = DummyContext.new("test")
      parent = subject.parent("", ctx)
      expect(parent).not_to be_nil
      expect(parent.parent).to eq("parent_test")
    end
  end

  context "requesting detect" do
    before do
      test_false_host = Class.new(Vagrant.plugin("2", :host)) do
        def detect?(env)
          false
        end
      end

      register_plugin do |p|
        p.host(:test_false) { test_false_host }
      end

      allow_any_instance_of(VagrantPlugins::CommandServe::Client::Target).to receive(:project).and_return("")
      allow_any_instance_of(VagrantPlugins::CommandServe::Client::Target).to receive(:name).and_return("dummy")
      allow_any_instance_of(VagrantPlugins::CommandServe::Client::Target).to receive(:provider_name).and_return("virtualbox")
    end

    after do
      VagrantPlugins::CommandServe.cache.clear
    end

    it "generates a spec" do
      spec = subject.detect_spec
      expect(spec).not_to be_nil
    end

    it "raises an error for unknown plugins" do
      ctx = DummyContext.new("idontexisthahaha")
      expect { subject.detect("", ctx) }.to raise_error(GRPC::BadStatus)
    end

    it "detects true plugins" do
      ctx = DummyContext.new("test")
      d = subject.detect(statebag_arg, ctx)
      expect(d.detected).to be true
    end

    it "detects false plugins" do
      ctx = DummyContext.new("test_false")
      d = subject.detect(statebag_arg, ctx)
      expect(d.detected).to be false
    end
  end

  context "requesting has capability" do
    before do
      cap_host = Class.new(Vagrant.plugin("2", :host)) do
        def detect?(env)
          true
        end
      end

      register_plugin do |p|
        p.host(:cap_host) { cap_host }
        p.host_capability(:cap_host, :mycap) do
          "this is a capability"
        end
      end
    end

    let(:named_cap_request){
      Hashicorp::Vagrant::Sdk::FuncSpec::Args.new(
        args: [
          Hashicorp::Vagrant::Sdk::FuncSpec::Value.new(
            name: "",
            type: "hashicorp.vagrant.sdk.Args.NamedCapability",
            value: Google::Protobuf::Any.pack(Hashicorp::Vagrant::Sdk::Args::NamedCapability.new(capability:"mycap")))
        ]
      )
    }

    let(:named_cap_bad_request){
      Hashicorp::Vagrant::Sdk::FuncSpec::Args.new(
        args: [
          Hashicorp::Vagrant::Sdk::FuncSpec::Value.new(
            name: "",
            type: "hashicorp.vagrant.sdk.Args.NamedCapability",
            value: Google::Protobuf::Any.pack(Hashicorp::Vagrant::Sdk::Args::NamedCapability.new(capability:"notacapability")))
        ]
      )
    }

    it "generates a spec" do
      spec = subject.has_capability_spec
      expect(spec).not_to be_nil
    end

    it "raises an error for unknown plugins" do
      ctx = DummyContext.new("idontexisthahaha")
      expect { subject.has_capability(test_cap_name, ctx) }.to raise_error(NameError)
    end

    it "returns true for plugin with capability" do
      ctx = DummyContext.new("cap_host")
      d = subject.has_capability(named_cap_request, ctx)
      expect(d.has_capability).to be true
    end

    it "returns false for plugin without capability" do
      ctx = DummyContext.new("cap_host")
      d = subject.has_capability(named_cap_bad_request, ctx)
      expect(d.has_capability).to be false
    end
  end
end
