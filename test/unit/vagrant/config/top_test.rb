require File.expand_path("../../../base", __FILE__)

require "vagrant/registry"

describe Vagrant::Config::Top do
  include_context "unit"

  let(:registry) { Vagrant::Registry.new }
  let(:instance) { described_class.new(registry) }

  it "should load in the proper config class" do
    registry.register(:foo, Object)

    instance.foo.should be_kind_of(Object)
  end

  it "should load the proper config class only once" do
    registry.register(:foo, Object)

    obj = instance.foo
    instance.foo.should eql(obj)
  end

  it "still raises a method missing error if invalid key" do
    expect { instance.foo }.to raise_error(NoMethodError)
  end
end
