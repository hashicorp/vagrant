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
      result.length.should == 2
      result[0].call.should == "bar"
      result[1].call.should == "baz"
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
      result.length.should == 3
      result[0].call.should == "bar"
      result[1].call.should == "bar_foo"
      result[2].call.should == "baz"
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

    instance.communicators.to_hash.length.should == 2
    instance.communicators[:foo].should == "bar"
    instance.communicators[:bar].should == "baz"
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

    instance.config.to_hash.length.should == 2
    instance.config[:foo].should == "bar"
    instance.config[:bar].should == "baz"
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

    instance.guests.to_hash.length.should == 2
    instance.guests[:foo].should == ["bar", nil]
    instance.guests[:bar].should == ["baz", :foo]
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

    instance.guest_capabilities.length.should == 2
    instance.guest_capabilities[:foo][:foo].should == "bar"
    instance.guest_capabilities[:bar][:foo].should == "baz"
  end

  it "should enumerate registered host classes" do
    pA = plugin do |p|
      p.host("foo") { "bar" }
    end

    pB = plugin do |p|
      p.host("bar") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    instance.hosts.to_hash.length.should == 2
    instance.hosts[:foo].should == "bar"
    instance.hosts[:bar].should == "baz"
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

    instance.providers.to_hash.length.should == 2
    instance.providers[:foo].should == ["bar", {}]
    instance.providers[:bar].should == ["baz", { foo: "bar" }]
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

    instance.provider_configs.to_hash.length.should == 2
    instance.provider_configs[:foo].should == "foo"
    instance.provider_configs[:bar].should == "bar"
  end
end
