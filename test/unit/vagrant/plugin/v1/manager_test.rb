require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V1::Manager do
  include_context "unit"

  let(:instance) { described_class.new }

  def plugin
    p = Class.new(Vagrant.plugin("1"))
    yield p
    p
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

    expect(instance.communicators.length).to eq(2)
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

    expect(instance.config.length).to eq(2)
    expect(instance.config[:foo]).to eq("bar")
    expect(instance.config[:bar]).to eq("baz")
  end

  it "should enumerate registered upgrade safe config classes" do
    pA = plugin do |p|
      p.config("foo", true) { "bar" }
    end

    pB = plugin do |p|
      p.config("bar") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.config_upgrade_safe.length).to eq(1)
    expect(instance.config_upgrade_safe[:foo]).to eq("bar")
  end

  it "should enumerate registered guest classes" do
    pA = plugin do |p|
      p.guest("foo") { "bar" }
    end

    pB = plugin do |p|
      p.guest("bar") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.guests.length).to eq(2)
    expect(instance.guests[:foo]).to eq("bar")
    expect(instance.guests[:bar]).to eq("baz")
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

    expect(instance.hosts.length).to eq(2)
    expect(instance.hosts[:foo]).to eq("bar")
    expect(instance.hosts[:bar]).to eq("baz")
  end

  it "should enumerate registered provider classes" do
    pA = plugin do |p|
      p.provider("foo") { "bar" }
    end

    pB = plugin do |p|
      p.provider("bar") { "baz" }
    end

    instance.register(pA)
    instance.register(pB)

    expect(instance.providers.length).to eq(2)
    expect(instance.providers[:foo]).to eq("bar")
    expect(instance.providers[:bar]).to eq("baz")
  end
end
