require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V2::Manager do
  include_context "unit"

  let(:instance) { described_class.new }

  def plugin
    p = Class.new(Vagrant.plugin("2"))
    yield p
    p
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
end
