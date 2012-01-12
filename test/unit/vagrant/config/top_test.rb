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

  describe "merging" do
    let(:foo_class) do
      Class.new do
        attr_accessor :one
        attr_accessor :two

        def merge(other)
          result = self.class.new
          result.one = other.one || one
          result.two = other.two || two
          result
        end
      end
    end

    it "merges each key by calling `merge` on the class" do
      registry.register(:foo, foo_class)

      instance.foo.one = 1
      instance.foo.two = 2

      another = described_class.new(registry)
      another.foo.one = 2

      result = instance.merge(another)
      result.foo.one.should == 2
      result.foo.two.should == 2
    end

    it "merges keys that aren't in the source instance" do
      reg = Vagrant::Registry.new
      reg.register(:foo, foo_class)

      another = described_class.new(reg)
      another.foo.one = 2

      result = instance.merge(another)
      result.foo.one.should == 2
      result.foo.two.should be_nil
    end
  end
end
