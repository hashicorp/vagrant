# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V2::Manager do
  include_context "unit"

  let(:instance) { described_class.new }

  def plugin
    p = Class.new(Vagrant.plugin("2"))
    yield p
    p
  end

  describe "#generate_hook_keys" do
    it "should return array with one value" do
      expect(subject.generate_hook_keys(:test_value)).to eq(["test_value"])
    end

    it "should return array with two values when key is camel cased" do
      result = subject.generate_hook_keys("TestValue")
      expect(result.size).to eq(2)
      expect(result).to include("TestValue")
      expect(result).to include("test_value")
    end

    it "should handle class/module value" do
      result = subject.generate_hook_keys(Vagrant)
      expect(result.size).to eq(2)
      expect(result).to include("Vagrant")
      expect(result).to include("vagrant")
    end

    it "should handle namespaced value" do
      result = subject.generate_hook_keys(Vagrant::Plugin)
      expect(result.size).to eq(4)
      expect(result).to include("Vagrant::Plugin")
      expect(result).to include("Plugin")
      expect(result).to include("vagrant_plugin")
      expect(result).to include("plugin")
    end
  end

  describe "#find_action_hooks" do
    let(:hook_name) { "Vagrant::Plugin" }

    before do
      h_name = hook_name
      pA = plugin do |p|
        p.action_hook(:test, h_name) { "hook_called" }
      end
      subject.register(pA)
    end

    it "should find hook with full namespace" do
      hooks = subject.find_action_hooks(Vagrant::Plugin)
      expect(hooks).not_to be_empty
      expect(hooks.first.call).to eq("hook_called")
    end

    it "should not find hook with short class name" do
      hooks = subject.find_action_hooks("Plugin")
      expect(hooks).to be_empty
    end

    it "should not find hook with full snake cased name" do
      hooks = subject.find_action_hooks(:vagrant_plugin)
      expect(hooks).to be_empty
    end

    it "should not find hook with short snake cased name" do
      hooks = subject.find_action_hooks("plugin")
      expect(hooks).to be_empty
    end

    context "when hook uses full snake cased name" do
      let(:hook_name) { :vagrant_plugin }

      it "should find hook with full namespace" do
        hooks = subject.find_action_hooks(Vagrant::Plugin)
        expect(hooks).not_to be_empty
        expect(hooks.first.call).to eq("hook_called")
      end

      it "should find hook with full snake cased name" do
        hooks = subject.find_action_hooks(:vagrant_plugin)
        expect(hooks).not_to be_empty
        expect(hooks.first.call).to eq("hook_called")
      end

      it "should not find hook with short class name" do
        hooks = subject.find_action_hooks("Plugin")
        expect(hooks).to be_empty
      end

      it "should not find hook with short snake cased name" do
        hooks = subject.find_action_hooks("plugin")
        expect(hooks).to be_empty
      end
    end

    context "when hook uses short snake cased name" do
      let(:hook_name) { :plugin }

      it "should find hook with full namespace" do
        hooks = subject.find_action_hooks(Vagrant::Plugin)
        expect(hooks).not_to be_empty
        expect(hooks.first.call).to eq("hook_called")
      end

      it "should find hook with short class name" do
        hooks = subject.find_action_hooks("Plugin")
        expect(hooks).not_to be_empty
        expect(hooks.first.call).to eq("hook_called")
      end

      it "should find hook with short snake cased name" do
        hooks = subject.find_action_hooks("plugin")
        expect(hooks).not_to be_empty
        expect(hooks.first.call).to eq("hook_called")
      end

      it "should not find hook with full snake cased name" do
        hooks = subject.find_action_hooks(:vagrant_plugin)
        expect(hooks).to be_empty
      end
    end

  end

  describe "#action_hooks" do
    it "should contain globally registered hooks" do
      pA = plugin do |p|
        p.action_hook("foo") { "bar" }
      end

      pB = plugin do |p|
        p.action_hook("bar") { "baz" }
      end

      instance.register(pA)
      instance.register(pB)

      result = instance.action_hooks(nil)
      expect(result.length).to eq(2)
      expect(result[0].call).to eq("bar")
      expect(result[1].call).to eq("baz")
    end

    it "should contain specific hooks with globally registered hooks" do
      pA = plugin do |p|
        p.action_hook("foo") { "bar" }
        p.action_hook("foo", :foo) { "bar_foo" }
        p.action_hook("foo", :bar) { "bar_bar" }
      end

      pB = plugin do |p|
        p.action_hook("bar") { "baz" }
      end

      instance.register(pA)
      instance.register(pB)

      result = instance.action_hooks(:foo)
      expect(result.length).to eq(3)
      expect(result[0].call).to eq("bar")
      expect(result[1].call).to eq("bar_foo")
      expect(result[2].call).to eq("baz")
    end
  end

  it "should enumerate registered communicator classes" do
    pA = plugin do |p|
      p.communicator("foo") { "bar" }
    end

    pB = plugin do |p|
      p.communicator("bar") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.communicators.to_hash.length).to eq(2)
    expect(instance.communicators[:foo]).to eq("bar")
    expect(instance.communicators[:bar]).to eq("baz")
  end

  it "should enumerate registered configuration classes" do
    pA = plugin do |p|
      p.config("foo") { "bar" }
    end

    pB = plugin do |p|
      p.config("bar") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.config.to_hash.length).to eq(2)
    expect(instance.config[:foo]).to eq("bar")
    expect(instance.config[:bar]).to eq("baz")
  end

  it "should enumerate registered guest classes" do
    pA = plugin do |p|
      p.guest("foo") { "bar" }
    end

    pB = plugin do |p|
      p.guest("bar", "foo") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.guests.to_hash.length).to eq(2)
    expect(instance.guests[:foo]).to eq(["bar", nil])
    expect(instance.guests[:bar]).to eq(["baz", :foo])
  end

  it "should enumerate registered guest capabilities" do
    pA = plugin do |p|
      p.guest_capability("foo", "foo") { "bar" }
    end

    pB = plugin do |p|
      p.guest_capability("bar", "foo") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.guest_capabilities.length).to eq(2)
    expect(instance.guest_capabilities[:foo][:foo]).to eq("bar")
    expect(instance.guest_capabilities[:bar][:foo]).to eq("baz")
  end

  it "should enumerate registered host classes" do
    pA = plugin do |p|
      p.host("foo") { "bar" }
    end

    pB = plugin do |p|
      p.host("bar", "foo") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.hosts.to_hash.length).to eq(2)
    expect(instance.hosts[:foo]).to eq(["bar", nil])
    expect(instance.hosts[:bar]).to eq(["baz", :foo])
  end

  it "should enumerate registered host capabilities" do
    pA = plugin do |p|
      p.host_capability("foo", "foo") { "bar" }
    end

    pB = plugin do |p|
      p.host_capability("bar", "foo") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.host_capabilities.length).to eq(2)
    expect(instance.host_capabilities[:foo][:foo]).to eq("bar")
    expect(instance.host_capabilities[:bar][:foo]).to eq("baz")
  end

  it "should enumerate registered provider classes" do
    pA = plugin do |p|
      p.provider("foo") { "bar" }
    end

    pB = plugin do |p|
      p.provider("bar", foo: "bar") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.providers.to_hash.length).to eq(2)
    expect(instance.providers[:foo]).to eq(["bar", { priority: 5 }])
    expect(instance.providers[:bar]).to eq(["baz", { foo: "bar", priority: 5 }])
  end

  it "provides the collection of registered provider configs" do
    pA = plugin do |p|
      p.config("foo", :provider) { "foo" }
    end

    pB = plugin do |p|
      p.config("bar", :provider) { "bar" }
      p.config("baz") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.provider_configs.to_hash.length).to eq(2)
    expect(instance.provider_configs[:foo]).to eq("foo")
    expect(instance.provider_configs[:bar]).to eq("bar")
  end

  it "should enumerate registered push classes" do
    pA = plugin do |p|
      p.push("foo") { "bar" }
    end

    pB = plugin do |p|
      p.push("bar", foo: "bar") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.pushes.to_hash.length).to eq(2)
    expect(instance.pushes[:foo]).to eq(["bar", nil])
    expect(instance.pushes[:bar]).to eq(["baz", { foo: "bar" }])
  end

  it "provides the collection of registered push configs" do
    pA = plugin do |p|
      p.config("foo", :push) { "foo" }
    end

    pB = plugin do |p|
      p.config("bar", :push) { "bar" }
      p.config("baz") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.push_configs.to_hash.length).to eq(2)
    expect(instance.push_configs[:foo]).to eq("foo")
    expect(instance.push_configs[:bar]).to eq("bar")
  end


  it "should enumerate all registered synced folder implementations" do
    pA = plugin do |p|
      p.synced_folder("foo") { "bar" }
    end

    pB = plugin do |p|
      p.synced_folder("bar", 50) { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.synced_folders.to_hash.length).to eq(2)
    expect(instance.synced_folders[:foo]).to eq(["bar", 10])
    expect(instance.synced_folders[:bar]).to eq(["baz", 50])
  end

  it "should enumerate registered synced_folder_capabilities classes" do
    pA = plugin do |p|
      p.synced_folder_capability("foo", "foo") { "bar" }
    end

    pB = plugin do |p|
      p.synced_folder_capability("bar", "bar") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.synced_folder_capabilities.to_hash.length).to eq(2)
    expect(instance.synced_folder_capabilities[:foo][:foo]).to eq("bar")
    expect(instance.synced_folder_capabilities[:bar][:bar]).to eq("baz")
  end

end
