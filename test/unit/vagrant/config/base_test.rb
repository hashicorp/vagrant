require File.expand_path("../../../base", __FILE__)

describe Vagrant::Config::Base do
  include_context "unit"

  let(:foo_class) do
    Class.new(described_class) do
      attr_accessor :one
      attr_accessor :two
    end
  end

  it "should merge by default by simply copying each instance variable" do
    one = foo_class.new
    one.one = 2
    one.two = 1

    two = foo_class.new
    two.two = 5

    result = one.merge(two)
    result.one.should == 2
    result.two.should == 5
  end

  it "doesn't merge values that start with a double underscore" do
    bar_class = Class.new(foo_class) do
      class_variable_set(:@@counter, 0)

      def initialize
        @__test = self.class.send(:class_variable_get, :@@counter)
        self.class.send(:class_variable_set, :@@counter, @__test + 1)
      end
    end

    one = bar_class.new
    one.one = 2
    one.two = 1

    two = bar_class.new
    two.two = 5

    # Verify the counters
    one.instance_variable_get(:@__test).should == 0
    two.instance_variable_get(:@__test).should == 1
    one.merge(two).instance_variable_get(:@__test).should == 2
  end
end
